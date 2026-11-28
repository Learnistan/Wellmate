import 'dart:convert';

import 'package:flutter/material.dart';

import '../majlis_theme.dart';

class MajlisTopic {
  final String id;
  final IconData icon;
  final MajlisJewel jewel;

  const MajlisTopic(this.id, this.icon, this.jewel);
}

/// Everyone in Majlis appears under a "veil": a name from a curated list and
/// a patterned avatar drawn from Afghan tilework. Never a real name or photo.
/// [id] is the Firebase uid; it is never shown.
class MajlisPerson {
  final String id;

  /// Key into the veil list ("red_tulip"); each phone shows it in its own language.
  final String veil;
  final int jewelIndex;

  /// Which picture the avatar uses (see MajlisPortraitArt: 7 women, 3 objects).
  final int motif;
  final bool isGuide;
  final String? guideName;

  const MajlisPerson({
    required this.id,
    required this.veil,
    required this.jewelIndex,
    required this.motif,
    this.isGuide = false,
    this.guideName,
  });

  MajlisJewel get jewel => MajlisJewels.all[jewelIndex.abs() % MajlisJewels.all.length];

  factory MajlisPerson.fromMap(Map<String, dynamic> m) => MajlisPerson(
        id: (m['uid'] ?? '') as String,
        veil: (m['veil'] ?? '') as String,
        jewelIndex: _int(m['jewel']),
        motif: _int(m['motif']).abs(),
        isGuide: m['guide'] == true,
        guideName: m['guideName'] as String?,
      );

  /// LiveKit participant metadata is the same map, as JSON.
  factory MajlisPerson.fromParticipant(String identity, String? metadata) {
    try {
      final m = (jsonDecode(metadata ?? '{}') as Map).cast<String, dynamic>();
      return MajlisPerson.fromMap({...m, 'uid': identity});
    } catch (_) {
      return MajlisPerson(id: identity, veil: '', jewelIndex: 0, motif: 0);
    }
  }

  MajlisPerson copyWith({String? veil, int? jewelIndex, int? motif}) => MajlisPerson(
        id: id,
        veil: veil ?? this.veil,
        jewelIndex: jewelIndex ?? this.jewelIndex,
        motif: motif ?? this.motif,
        isGuide: isGuide,
        guideName: guideName,
      );

  @override
  bool operator ==(Object other) => other is MajlisPerson && other.id == id && other.veil == veil;

  @override
  int get hashCode => Object.hash(id, veil);
}

int _int(Object? v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);

enum MajlisAudience { open, women, invite }

enum MajlisStatus { scheduled, live, ended, cancelled, missed }

class MajlisPin {
  final String text;
  final bool whisper;
  const MajlisPin(this.text, this.whisper);
}

class MajlisTurn {
  final String uid;
  final DateTime? startedAt;
  const MajlisTurn(this.uid, this.startedAt);
}

/// A space, live or scheduled. Written only by Cloud Functions.
class MajlisSpace {
  final String id;
  final String title;
  final String topicId;

  /// 'fa' (Dari), 'ps' (Pashto) or 'en'.
  final String lang;
  final MajlisAudience audience;
  final String? question;
  final bool turns;
  final String hostUid;
  final MajlisPerson host;
  final MajlisStatus status;
  final DateTime? scheduledFor;
  final DateTime? startedAt;
  final String? inviteCode;
  final List<String> speakerUids;
  final List<String> invitedUids;
  final List<String> hands;
  final List<MajlisPerson> stage;
  final int listenerCount;
  final int goingCount;
  final MajlisPin? pinned;
  final MajlisTurn? turn;
  final DateTime? hostAwaySince;

  const MajlisSpace({
    required this.id,
    required this.title,
    required this.topicId,
    required this.lang,
    required this.audience,
    required this.hostUid,
    required this.host,
    required this.status,
    this.question,
    this.turns = false,
    this.scheduledFor,
    this.startedAt,
    this.inviteCode,
    this.speakerUids = const [],
    this.invitedUids = const [],
    this.hands = const [],
    this.stage = const [],
    this.listenerCount = 0,
    this.goingCount = 0,
    this.pinned,
    this.turn,
    this.hostAwaySince,
  });

  bool get isLive => status == MajlisStatus.live;
  bool get isScheduled => status == MajlisStatus.scheduled;
  int get people => listenerCount + stage.length;
}

/// The signed-in user's own Majlis profile. Only they can read it.
class MajlisProfile {
  final String uid;
  final String? veil;
  final int jewel;
  final int motif;
  final bool womenSpaces;
  final List<String> blocked;
  final int joined;
  final int minutes;
  final int tea;
  final int hosted;

  const MajlisProfile({
    required this.uid,
    this.veil,
    this.jewel = 0,
    this.motif = 0,
    this.womenSpaces = false,
    this.blocked = const [],
    this.joined = 0,
    this.minutes = 0,
    this.tea = 0,
    this.hosted = 0,
  });

  bool get hasVeil => veil != null && veil!.isNotEmpty;

  MajlisPerson get person => MajlisPerson(id: uid, veil: veil ?? '', jewelIndex: jewel, motif: motif);
}

class MajlisWhisper {
  final String id;
  final String text;
  final DateTime? at;
  final bool pinned;
  const MajlisWhisper(this.id, this.text, this.at, this.pinned);
}

/// What majlisJoin returns.
class MajlisJoin {
  final String spaceId;
  final String status;
  final String? token;
  final String? url;
  final String role;

  /// The host, or a WellMate guide: may mute, move, remove and end.
  final bool moderator;

  const MajlisJoin({
    required this.spaceId,
    required this.status,
    this.token,
    this.url,
    this.role = 'listener',
    this.moderator = false,
  });

  bool get isHost => role == 'host';
}

/// What the room hands back to the hallway when you leave.
class MajlisLeaveResult {
  final String spaceTitle;
  final Duration sat;
  final int teaReceived;
  final bool spoke;
  final bool hosted;

  /// Why the room closed: null when you left yourself.
  final String? reason;

  const MajlisLeaveResult({
    required this.spaceTitle,
    required this.sat,
    required this.teaReceived,
    required this.spoke,
    required this.hosted,
    this.reason,
  });
}

/// A failure with a key the app can translate (see MajlisStrings.error).
class MajlisException implements Exception {
  final String code;
  final String? spaceId;
  const MajlisException(this.code, {this.spaceId});

  @override
  String toString() => 'MajlisException($code)';
}
