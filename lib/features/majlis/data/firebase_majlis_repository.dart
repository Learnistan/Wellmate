import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../domain/majlis_models.dart';
import '../domain/majlis_repository.dart';

/// Majlis on Firebase: reads from Firestore, writes through Cloud Functions
/// (functions/majlis.js). The only thing the app writes directly is the
/// user's own profile, and firestore.rules checks it.
class FirebaseMajlisRepository implements MajlisRepository {
  /// Where the Majlis Cloud Functions run: Delhi, next to WellMate's Firestore.
  static const functionsRegion = 'asia-south2';

  FirebaseMajlisRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _fns = functions ?? FirebaseFunctions.instanceFor(region: functionsRegion);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseFunctions _fns;

  @override
  String? get uid => _auth.currentUser?.uid;

  String get _me => uid ?? (throw const MajlisException('sign-in'));

  CollectionReference<Map<String, dynamic>> get _spaces => _db.collection('majlis_spaces');
  DocumentReference<Map<String, dynamic>> get _profile => _db.collection('majlis_profiles').doc(_me);

  // ---- Profile ----------------------------------------------------------------

  @override
  Stream<MajlisProfile?> watchProfile() {
    final id = uid;
    if (id == null) return Stream.value(null);
    return _db.collection('majlis_profiles').doc(id).snapshots().map((s) {
      final d = s.data();
      if (d == null) return MajlisProfile(uid: id);
      final stats = (d['stats'] as Map?)?.cast<String, dynamic>() ?? const {};
      return MajlisProfile(
        uid: id,
        veil: d['veil'] as String?,
        jewel: _int(d['jewel']),
        motif: _int(d['motif']),
        womenSpaces: d['womenSpaces'] == true,
        blocked: List<String>.from(d['blocked'] ?? const []),
        joined: _int(stats['joined']),
        minutes: _int(stats['minutes']),
        tea: _int(stats['tea']),
        hosted: _int(stats['hosted']),
      );
    });
  }

  @override
  Future<void> saveVeil({required String veil, required int jewel, required int motif}) async {
    final ref = _profile;
    final exists = (await ref.get()).exists;
    final data = {'veil': veil, 'jewel': jewel, 'motif': motif, 'updatedAt': FieldValue.serverTimestamp()};
    if (exists) {
      await ref.update(data);
    } else {
      await ref.set({...data, 'createdAt': FieldValue.serverTimestamp(), 'womenSpaces': false, 'blocked': <String>[]});
    }
  }

  @override
  Future<void> setWomenSpaces(bool value) =>
      _profile.update({'womenSpaces': value, 'updatedAt': FieldValue.serverTimestamp()});

  @override
  Future<void> setBlocked(String other, bool blocked) => _profile.update({
        'blocked': blocked ? FieldValue.arrayUnion([other]) : FieldValue.arrayRemove([other]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> unblockAll() => _profile.update({'blocked': <String>[], 'updatedAt': FieldValue.serverTimestamp()});

  // ---- Spaces -----------------------------------------------------------------

  @override
  Stream<List<MajlisSpace>> watchLive() => _spaces
      .where('status', isEqualTo: 'live')
      .where('audience', whereIn: ['open', 'women'])
      .orderBy('startedAt', descending: true)
      .limit(50)
      .snapshots()
      .map(_list);

  @override
  Stream<List<MajlisSpace>> watchScheduled() => _spaces
      .where('status', isEqualTo: 'scheduled')
      .where('audience', whereIn: ['open', 'women'])
      .orderBy('scheduledFor')
      .limit(30)
      .snapshots()
      .map(_list);

  @override
  Stream<List<MajlisSpace>> watchMine() {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return _spaces
        .where('hostUid', isEqualTo: id)
        .where('status', whereIn: ['live', 'scheduled'])
        .snapshots()
        .map(_list);
  }

  @override
  Stream<MajlisSpace?> watchSpace(String spaceId) =>
      _spaces.doc(spaceId).snapshots().map((s) => s.exists ? _space(s.id, s.data()!) : null);

  @override
  Stream<Set<String>> watchGoing() {
    final id = uid;
    if (id == null) return Stream.value(const {});
    return _db
        .collectionGroup('going')
        .where('uid', isEqualTo: id)
        .snapshots()
        .map((q) => {for (final d in q.docs) d.reference.parent.parent!.id});
  }

  @override
  Stream<List<MajlisWhisper>> watchWhispers(String spaceId) => _spaces
      .doc(spaceId)
      .collection('whispers')
      .orderBy('at', descending: true)
      .limit(50)
      .snapshots()
      .map((q) => [
            for (final d in q.docs)
              MajlisWhisper(d.id, (d.data()['text'] ?? '') as String, _date(d.data()['at']), d.data()['pinned'] == true),
          ]);

  // ---- Calls ------------------------------------------------------------------

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
    try {
      final r = await _fns.httpsCallable(name, options: HttpsCallableOptions(timeout: const Duration(seconds: 20))).call(data);
      return (r.data as Map?)?.cast<String, dynamic>() ?? const {};
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Majlis $name failed: ${e.code} ${e.message}');
      final details = e.details is Map ? (e.details as Map).cast<String, dynamic>() : const <String, dynamic>{};
      final code = switch (e.code) {
        'unavailable' || 'deadline-exceeded' => 'network',
        'internal' when (e.message ?? '').toLowerCase() == 'internal' => 'generic',
        _ => e.message ?? 'generic',
      };
      throw MajlisException(code, spaceId: details['spaceId'] as String?);
    } catch (e) {
      debugPrint('Majlis $name failed: $e');
      throw const MajlisException('network');
    }
  }

  @override
  Future<({String spaceId, String? inviteCode})> createSpace({
    required String title,
    required String topic,
    required String lang,
    required MajlisAudience audience,
    String? question,
    bool turns = false,
    DateTime? startsAt,
  }) async {
    final r = await _call('majlisCreateSpace', {
      'title': title,
      'topic': topic,
      'lang': lang,
      'audience': audience.name,
      'question': question,
      'turns': turns,
      'startsAt': startsAt?.millisecondsSinceEpoch,
    });
    return (spaceId: r['spaceId'] as String, inviteCode: r['inviteCode'] as String?);
  }

  @override
  Future<MajlisJoin> join({String? spaceId, String? code}) async {
    final r = await _call('majlisJoin', {'spaceId': ?spaceId, 'code': ?code});
    return MajlisJoin(
      spaceId: r['spaceId'] as String,
      status: (r['status'] ?? 'live') as String,
      token: r['token'] as String?,
      url: r['url'] as String?,
      role: (r['role'] ?? 'listener') as String,
      moderator: r['moderator'] == true,
    );
  }

  @override
  Future<void> stage(String spaceId, String action, {String? target, bool? up}) =>
      _call('majlisStage', {'spaceId': spaceId, 'action': action, 'target': ?target, 'up': ?up});

  @override
  Future<void> host(String spaceId, String action, {String? target, String? text, String? whisperId, bool? on}) =>
      _call('majlisHost', {
        'spaceId': spaceId,
        'action': action,
        'target': ?target,
        'text': ?text,
        'whisperId': ?whisperId,
        'on': ?on,
      });

  @override
  Future<void> whisper(String spaceId, String text) => _call('majlisWhisper', {'spaceId': spaceId, 'text': text});

  @override
  Future<void> tea(String spaceId, String to) => _call('majlisTea', {'spaceId': spaceId, 'to': to});

  @override
  Future<int> remind(String spaceId, bool on) async {
    final r = await _call('majlisRemind', {'spaceId': spaceId, 'on': on});
    return _int(r['goingCount']);
  }

  @override
  Future<void> report({String? spaceId, String? target, required String reason, String? note}) =>
      _call('majlisReport', {'spaceId': ?spaceId, 'target': ?target, 'reason': reason, 'note': ?note});

  // ---- Mapping ----------------------------------------------------------------

  List<MajlisSpace> _list(QuerySnapshot<Map<String, dynamic>> q) => [for (final d in q.docs) _space(d.id, d.data())];

  static MajlisSpace _space(String id, Map<String, dynamic> d) {
    final host = MajlisPerson.fromMap((d['host'] as Map?)?.cast<String, dynamic>() ?? {'uid': d['hostUid']});
    final pin = (d['pinned'] as Map?)?.cast<String, dynamic>();
    final turn = (d['turn'] as Map?)?.cast<String, dynamic>();
    return MajlisSpace(
      id: id,
      title: (d['title'] ?? '') as String,
      topicId: (d['topic'] ?? 'chai') as String,
      lang: (d['lang'] ?? 'en') as String,
      audience: MajlisAudience.values.firstWhere((a) => a.name == d['audience'], orElse: () => MajlisAudience.open),
      question: d['question'] as String?,
      turns: d['turns'] == true,
      hostUid: (d['hostUid'] ?? '') as String,
      host: host,
      status: MajlisStatus.values.firstWhere((s) => s.name == d['status'], orElse: () => MajlisStatus.ended),
      scheduledFor: _date(d['scheduledFor']),
      startedAt: _date(d['startedAt']),
      inviteCode: d['inviteCode'] as String?,
      speakerUids: List<String>.from(d['speakerUids'] ?? const []),
      invitedUids: List<String>.from(d['invitedUids'] ?? const []),
      hands: List<String>.from(d['hands'] ?? const []),
      stage: [
        for (final p in (d['stage'] as List? ?? const []))
          MajlisPerson.fromMap((p as Map).cast<String, dynamic>()),
      ],
      listenerCount: _int(d['listenerCount']),
      goingCount: _int(d['goingCount']),
      pinned: pin == null ? null : MajlisPin((pin['text'] ?? '') as String, pin['whisper'] == true),
      turn: turn == null ? null : MajlisTurn((turn['uid'] ?? '') as String, _date(turn['startedAt'])),
      hostAwaySince: _date(d['hostAwaySince']),
    );
  }

  static DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;
  static int _int(Object? v) => v is int ? v : (v is num ? v.toInt() : 0);
}
