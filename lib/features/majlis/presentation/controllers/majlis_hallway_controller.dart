import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/majlis_models.dart';
import '../../domain/majlis_repository.dart';
import '../../l10n/majlis_strings.dart';
import '../../majlis_config.dart';

/// Hallway state: live and scheduled spaces, your profile, your reminders.
/// Everything streams from Firestore, so the hallway updates by itself.
class MajlisHallway extends ChangeNotifier {
  MajlisHallway({required this.repo, required this.config}) {
    _listen();
  }

  final MajlisRepository repo;
  final MajlisConfig config;

  MajlisProfile? profile;
  bool profileLoaded = false;
  bool spacesLoaded = false;
  bool offline = false;
  Set<String> going = {};

  List<MajlisSpace> _live = const [];
  List<MajlisSpace> _scheduled = const [];
  List<MajlisSpace> _mine = const [];
  final List<StreamSubscription<Object?>> _subs = [];
  bool _disposed = false;

  void _listen() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    void fail(Object e) {
      debugPrint('Majlis hallway stream error: $e');
      offline = true;
      _notify();
    }

    _subs
      ..add(repo.watchProfile().listen((p) {
        profile = p;
        profileLoaded = true;
        _notify();
      }, onError: fail))
      ..add(repo.watchLive().listen((l) {
        _live = l;
        spacesLoaded = true;
        offline = false;
        _notify();
      }, onError: fail))
      ..add(repo.watchScheduled().listen((l) {
        _scheduled = l;
        _notify();
      }, onError: fail))
      ..add(repo.watchMine().listen((l) {
        _mine = l;
        _notify();
      }, onError: fail))
      ..add(repo.watchGoing().listen((g) {
        going = g;
        _notify();
      }, onError: fail));
  }

  void retry() {
    offline = false;
    _notify();
    _listen();
  }

  String? get uid => repo.uid;
  bool get hasVeil => profile?.hasVeil ?? false;
  MajlisPerson? get me => hasVeil ? profile!.person : null;
  Set<String> get blocked => {...?profile?.blocked};

  bool isMine(MajlisSpace s) => s.hostUid == uid;

  /// Live spaces: yours first, then guide-led, then the busiest.
  List<MajlisSpace> get live {
    final all = {for (final s in [..._mine, ..._live]) s.id: s}.values.where((s) => s.isLive);
    final list = all.where((s) => isMine(s) || !blocked.contains(s.hostUid)).toList()
      ..sort((a, b) {
        if (isMine(a) != isMine(b)) return isMine(a) ? -1 : 1;
        if (a.host.isGuide != b.host.isGuide) return a.host.isGuide ? -1 : 1;
        return b.people.compareTo(a.people);
      });
    return list;
  }

  List<MajlisSpace> get scheduled {
    final all = {for (final s in [..._mine, ..._scheduled]) s.id: s}.values.where((s) => s.isScheduled);
    return all.where((s) => isMine(s) || !blocked.contains(s.hostUid)).toList()
      ..sort((a, b) => (a.scheduledFor ?? DateTime(3000)).compareTo(b.scheduledFor ?? DateTime(3000)));
  }

  int get peopleNow => live.fold(0, (sum, s) => sum + s.people);

  MajlisSpace? get myLiveSpace => _mine.where((s) => s.isLive).firstOrNull;

  // ---- Actions --------------------------------------------------------------

  Future<void> saveVeil(String veil, int jewel, int motif) =>
      repo.saveVeil(veil: veil, jewel: jewel, motif: motif);

  Future<void> confirmWomen() => repo.setWomenSpaces(true);

  Future<void> setWomenSpaces(bool v) => repo.setWomenSpaces(v);

  Future<void> unblockAll() => repo.unblockAll();

  /// Remind me / going. Schedules a local notification when WellMate gives us a reminder service.
  Future<void> remind(MajlisSpace s, bool on, MajlisStrings l) async {
    going = on ? ({...going, s.id}) : ({...going}..remove(s.id));
    _notify();
    try {
      await repo.remind(s.id, on);
    } catch (_) {
      going = on ? ({...going}..remove(s.id)) : ({...going, s.id});
      _notify();
      rethrow;
    }
    // The local notification is a bonus: if the phone refuses it, the person
    // still counts as going.
    final r = config.reminders;
    if (r == null) return;
    try {
      if (on) {
        await r.schedule(s,
            title: l.t('majlis'),
            body: l.t('reminderBody', {'title': s.title, 'time': l.time(s.scheduledFor ?? DateTime.now())}));
      } else {
        await r.cancel(s.id);
      }
    } catch (e) {
      debugPrint('Majlis reminder failed: $e');
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
