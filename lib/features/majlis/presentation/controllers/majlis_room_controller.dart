import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/majlis_catalog.dart';
import '../../domain/majlis_models.dart';
import '../../domain/majlis_repository.dart';
import '../../domain/majlis_voice.dart';
import '../../l10n/majlis_strings.dart';
import '../../majlis_config.dart';
import '../../majlis_trace.dart';

class MajlisReaction {
  MajlisReaction(this.id, this.kind, this.x, this.mine);
  final int id;
  final String kind;

  /// 0..1 from the start edge (left in English, right in Dari and Pashto).
  final double x;
  final bool mine;
}

/// A short note at the top of the room. Text is built in the user's language.
class MajlisToast {
  MajlisToast(this.id, this.text, this.icon, {this.action, this.actionLabel});
  final int id;
  final String Function(MajlisStrings l) text;
  final IconData icon;
  final VoidCallback? action;
  final String Function(MajlisStrings l)? actionLabel;
}

enum MajlisRoomPhase { joining, live, closed, failed }

/// One live space: the voice connection (LiveKit) plus the space document
/// (Firestore). Everyone's stage seat, hand and pin come from the server;
/// reactions and tea travel as small room messages.
class MajlisRoomController extends ChangeNotifier with WidgetsBindingObserver {
  MajlisRoomController({
    required this.repo,
    required this.voice,
    required this.spaceId,
    required this.me,
    this.space,
    this.config = const MajlisConfig(),
    Set<String> blocked = const {},
  }) : blocked = {...blocked};

  final MajlisRepository repo;
  final MajlisVoice voice;
  final String spaceId;
  final MajlisPerson me;
  final Set<String> blocked;

  /// WellMate's settings (invite links and so on).
  final MajlisConfig config;

  MajlisSpace? space;
  MajlisRoomPhase phase = MajlisRoomPhase.joining;
  String? error;

  /// Why the room closed, as a string key ("endedByHost", "removedYou"...); null if you left.
  String? closeReason;
  bool isHost = false;

  /// A WellMate guide who is not the host: gets the safety tools only.
  bool isGuideModerator = false;

  /// May mute, move back to listening, remove and end (host or guide).
  bool get canModerate => isHost || isGuideModerator;

  List<MajlisWhisper> whispers = const [];
  final Map<String, int> tea = {};
  int teaForMe = 0;
  final List<MajlisReaction> reactions = [];
  MajlisToast? toast;
  final Set<String> mutedForMe = {};

  bool breathePrompt = false;
  bool breathing = false;
  bool breathingTogether = false;
  bool inviteDismissed = false;
  bool spoke = false;
  final DateTime joinedAt = DateTime.now();

  bool _accepting = false;
  bool _leavingStage = false;

  /// True while the user wants their mic open. If the mic goes off while this
  /// is still true, the host muted them (LiveKit reports both the same way).
  bool _wantMic = false;
  bool _pausedMic = false;
  bool _inBackground = false;
  bool _recovering = false;
  int _reconnectingSeconds = 0;
  String? _speakingId;
  Timer? _speakHold;
  DateTime _lastReaction = DateTime(2000);
  bool _advancingTurn = false;
  bool _wasSpeaker = false;
  bool _wasMicOn = false;
  bool? _handOverride;
  int _id = 0;
  bool _disposed = false;
  final _rand = Random();
  final List<StreamSubscription<Object?>> _subs = [];
  final List<Timer> _timers = [];
  Timer? _toastTimer;
  Timer? _tick;

  // ---- Derived ----------------------------------------------------------------

  List<MajlisVoicePeer> get _visible => voice.peers.where((p) => !blocked.contains(p.id)).toList();

  String get hostUid => space?.hostUid ?? (isHost ? me.id : '');

  MajlisPerson get host => space?.host ?? me;

  List<MajlisVoicePeer> get stage {
    final order = space?.speakerUids ?? const <String>[];
    return _visible.where((p) => p.canSpeak).toList()
      ..sort((a, b) {
        if (a.id == hostUid) return -1;
        if (b.id == hostUid) return 1;
        final ia = order.indexOf(a.id), ib = order.indexOf(b.id);
        if (ia != ib) return (ia < 0 ? 999 : ia).compareTo(ib < 0 ? 999 : ib);
        return a.joinedAt.compareTo(b.joinedAt);
      });
  }

  List<MajlisVoicePeer> get listeners {
    final hands = space?.hands ?? const <String>[];
    return _visible.where((p) => !p.canSpeak).toList()
      ..sort((a, b) {
        if (a.isLocal) return -1;
        if (b.isLocal) return 1;
        final ha = hands.contains(a.id), hb = hands.contains(b.id);
        if (ha != hb) return ha ? -1 : 1;
        return a.joinedAt.compareTo(b.joinedAt);
      });
  }

  /// Who to name as speaking: someone else first, then you. The name stays
  /// for a moment after they pause, so it doesn't flicker between sentences.
  MajlisVoicePeer? get speaking =>
      _speakingId == null ? null : stage.where((p) => p.id == _speakingId && !mutedForMe.contains(p.id)).firstOrNull;

  void _trackSpeaker() {
    final s = stage.where((p) => p.speaking && !mutedForMe.contains(p.id)).toList();
    final now = s.where((p) => !p.isLocal).firstOrNull ?? s.firstOrNull;
    if (now != null) {
      _speakHold?.cancel();
      _speakHold = null;
      _speakingId = now.id;
    } else if (_speakingId != null && _speakHold == null) {
      _speakHold = Timer(const Duration(milliseconds: 1600), () {
        _speakHold = null;
        _speakingId = null;
        _notify();
      });
    }
  }

  bool get onStage => voice.canSpeak;
  bool get micOn => voice.micOn;
  /// "Reconnecting…" shows only when the trouble lasts over 1.5 s: a server
  /// mute or a network switch can blip the connection for a few milliseconds.
  bool get reconnecting => phase == MajlisRoomPhase.live && _troubleShown;

  bool _troubleShown = false;
  Timer? _troubleTimer;

  void _trackTrouble() {
    // Only once live: the first connect is covered by the joining screen.
    final trouble = phase == MajlisRoomPhase.live &&
        (voice.state == MajlisVoiceState.reconnecting || voice.state == MajlisVoiceState.connecting);
    if (!trouble) {
      _troubleTimer?.cancel();
      _troubleTimer = null;
      _troubleShown = false;
      return;
    }
    if (_troubleShown || _troubleTimer != null) return;
    _troubleTimer = Timer(const Duration(milliseconds: 1500), () {
      _troubleTimer = null;
      _troubleShown = true;
      majlisTrace('reconnecting banner shown');
      _notify();
    });
  }

  /// This phone's connection to the voice server (shown when it is weak).
  MajlisLinkQuality get linkQuality => voice.linkQuality;
  bool get canPlayAudio => voice.canPlayAudio;
  bool get handRaised => _handOverride ?? (space?.hands.contains(me.id) ?? false);
  bool get invited =>
      !isHost && !onStage && !inviteDismissed && (space?.invitedUids.contains(me.id) ?? false);
  bool get turns => space?.turns ?? false;
  MajlisTurn? get turn => turns ? space?.turn : null;
  String? get pinned => space?.pinned?.text;
  bool get pinnedIsWhisper => space?.pinned?.whisper ?? false;
  int get listeningCount => listeners.length;
  int get peopleCount => _visible.length;

  bool get hostAway =>
      !isHost && phase == MajlisRoomPhase.live && !voice.peers.any((p) => p.id == hostUid);

  /// Raised hands the host can act on, oldest first.
  List<MajlisPerson> get hands {
    final peers = {for (final p in voice.peers) p.id: p.person};
    return [
      for (final id in space?.hands ?? const <String>[])
        if (peers[id] != null && !blocked.contains(id)) peers[id]!,
    ];
  }

  MajlisPerson? personById(String id) => voice.peers.where((p) => p.id == id).firstOrNull?.person;

  // ---- Joining ----------------------------------------------------------------

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    voice.addListener(_onVoice);
    _subs.add(voice.signals.listen(_onSignal));
    try {
      final j = await repo.join(spaceId: spaceId);
      if (j.status != 'live' || j.token == null) throw const MajlisException('not-started');
      isHost = j.isHost;
      isGuideModerator = j.moderator && !j.isHost;
      _subs.add(repo.watchSpace(spaceId).listen(_onSpace, onError: (_) {}));
      if (isHost) {
        _subs.add(repo.watchWhispers(spaceId).listen((w) {
          whispers = w;
          _notify();
        }, onError: (_) {}));
      }
      await voice.connect(j.url!, j.token!);
      if (_disposed) return;
      phase = MajlisRoomPhase.live;
      for (final b in blocked) {
        await voice.muteFor(b, true);
      }
      _wasSpeaker = voice.canSpeak;
      _notify();
      if (voice.canSpeak) await _openMic();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => _turnTick());
    } on MajlisException catch (e) {
      _fail(e.code);
    } catch (e) {
      debugPrint('Majlis join failed: $e');
      _fail('sound');
    }
  }

  /// After a failed join: try once more with a fresh token.
  Future<void> retry() async {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _tick?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    voice.removeListener(_onVoice);
    await voice.leave().catchError((_) {});
    phase = MajlisRoomPhase.joining;
    error = null;
    _notify();
    await start();
  }

  void _fail(String code) {
    if (_disposed) return;
    phase = MajlisRoomPhase.failed;
    error = code;
    _notify();
  }

  void _onSpace(MajlisSpace? s) {
    if (s == null) return _close('endedByHost');
    final wasInvited = space?.invitedUids.contains(me.id) ?? false;
    space = s;
    if (s.invitedUids.contains(me.id) && !wasInvited) inviteDismissed = false;
    _handOverride = null;
    if (!s.isLive && phase == MajlisRoomPhase.live) return _close(isHost ? null : 'endedByHost');
    _notify();
  }

  MajlisVoiceState? _lastState;

  void _onVoice() {
    if (phase == MajlisRoomPhase.closed) return;
    if (voice.state != _lastState) {
      majlisTrace('voice ${_lastState?.name} -> ${voice.state.name}${voice.state == MajlisVoiceState.disconnected ? ' (${voice.end.name})' : ''}');
      _lastState = voice.state;
    }
    // Closing comes first: losing the stage or the mic on the way out is not
    // news ("moved you back to listening" / "muted your mic" after Leave).
    if (voice.state == MajlisVoiceState.disconnected && phase == MajlisRoomPhase.live) {
      _close(switch (voice.end) {
        MajlisVoiceEnd.ended => 'endedByHost',
        MajlisVoiceEnd.removed => 'removedYou',
        MajlisVoiceEnd.otherDevice => 'otherDevice',
        MajlisVoiceEnd.failed => 'connectionLost',
        _ => null,
      });
      return;
    }
    _trackTrouble();
    final speaker = voice.canSpeak;
    if (speaker != _wasSpeaker) majlisTrace(speaker ? 'can speak' : 'listener now');
    if (speaker && !_wasSpeaker) {
      if (_accepting) {
        _accepting = false;
        _openMic(announce: true);
      }
    } else if (!speaker && _wasSpeaker) {
      _wantMic = false;
      if (!_leavingStage && !isHost) _toast((l) => l.t('movedToListeners'), Icons.headphones_rounded);
      _leavingStage = false;
    }
    _wasSpeaker = speaker;

    final mic = voice.micOn;
    if (mic != _wasMicOn) majlisTrace('mic ${mic ? 'on' : 'off'} (wanted: $_wantMic)');
    if (_wasMicOn && !mic && speaker && _wantMic && !_pausedMic) {
      _wantMic = false;
      _toast((l) => l.t('hostMutedYou'), Icons.mic_off_rounded);
    }
    _wasMicOn = mic;
    _trackSpeaker();
    _notify();
  }

  void _onSignal(MajlisSignal s) {
    final from = s.from;
    majlisTrace('signal ${s.topic} from ${from == null ? 'server' : from.substring(0, from.length.clamp(0, 6))}');
    if (from != null && blocked.contains(from)) return;
    switch (s.topic) {
      case 'majlis.react':
        final k = s.data['k'];
        if (k is String && MajlisCatalog.allReactions.any((r) => r.id == k)) _float(k, mine: false);
      case 'majlis.tea':
        final to = s.data['to'];
        if (to is! String) return;
        tea[to] = (tea[to] ?? 0) + 1;
        _float('tea', mine: false);
        if (to == me.id) {
          teaForMe++;
          final giver = from == null ? null : personById(from);
          if (giver != null) _toast((l) => l.t('pouredYou', {'name': l.name(giver)}), Icons.local_cafe_rounded);
        }
        _notify();
      case 'majlis.breathe':
        if (from == hostUid && !isHost && !breathing) {
          breathePrompt = true;
          _notify();
        }
      case 'majlis.invite':
        if (from == null) {
          inviteDismissed = false;
          _notify();
        }
      case 'majlis.autoMuted':
        final who = s.data['target'];
        final p = who is String ? personById(who) : null;
        if (from == null && p != null) {
          _toast((l) => l.t('autoMuted', {'name': l.name(p)}), Icons.shield_outlined, ms: 5000);
        }
      case 'majlis.lowered':
        if (from == null) {
          _handOverride = false;
          _toast((l) => l.t('hostSaidNotNow'), Icons.front_hand_outlined);
        }
    }
  }

  // ---- Everyone -----------------------------------------------------------------

  void react(String kind) {
    // Reliable delivery: lossy packets from other clients were not arriving
    // on Android. Reactions are tiny, so a short gap keeps traffic low.
    final now = DateTime.now();
    if (now.difference(_lastReaction).inMilliseconds < 350) return;
    _lastReaction = now;
    _float(kind, mine: true);
    voice.send('majlis.react', {'k': kind});
  }

  void _float(String kind, {required bool mine}) {
    final id = ++_id;
    final x = mine ? 0.70 + _rand.nextDouble() * 0.16 : 0.06 + _rand.nextDouble() * 0.2;
    reactions.add(MajlisReaction(id, kind, x, mine));
    if (reactions.length > 18) reactions.removeAt(0);
    _later(2900, () {
      reactions.removeWhere((r) => r.id == id);
      _notify();
    });
    _notify();
  }

  void pourTea(MajlisPerson p) {
    if (p.id == me.id) return;
    tea[p.id] = (tea[p.id] ?? 0) + 1;
    _float('tea', mine: true);
    voice.send('majlis.tea', {'to': p.id});
    repo.tea(spaceId, p.id).catchError((_) {});
    _toast((l) => l.t('pouredTea', {'name': l.name(p)}), Icons.local_cafe_rounded);
  }

  void pourTeaForSpeaker() {
    final p = speaking;
    if (p == null || p.isLocal) {
      _toast((l) => l.t('teaToSpeaker'), Icons.local_cafe_rounded);
      return;
    }
    pourTea(p.person);
  }

  Future<void> toggleMuteForMe(MajlisPerson p) async {
    final mute = !mutedForMe.contains(p.id);
    mute ? mutedForMe.add(p.id) : mutedForMe.remove(p.id);
    await voice.muteFor(p.id, mute);
    _toast(
      (l) => l.t(mute ? 'mutedForMe' : 'hearAgain', {'name': l.name(p)}),
      mute ? Icons.volume_off_rounded : Icons.volume_up_rounded,
    );
  }

  Future<void> report(MajlisPerson? p, String reason) async {
    await _try(() => repo.report(spaceId: spaceId, target: p?.id, reason: reason));
    _toast((l) => l.t('reported'), Icons.flag_outlined);
  }

  Future<void> block(MajlisPerson p) async {
    blocked.add(p.id);
    await voice.muteFor(p.id, true);
    _toast((l) => l.t('blocked', {'name': l.name(p)}), Icons.block_rounded);
    await _try(() => repo.setBlocked(p.id, true));
    if (isHost) await _try(() => repo.host(spaceId, 'remove', target: p.id));
  }

  Future<void> sendWhisper(String text) async {
    final ok = await _try(() => repo.whisper(spaceId, text));
    if (ok) _toast((l) => l.t('whisperSent', {'name': l.name(host)}), Icons.mail_lock_rounded);
  }

  void startBreathing({bool together = false}) {
    breathePrompt = false;
    breathing = true;
    breathingTogether = together;
    _notify();
  }

  void stopBreathing() {
    breathing = false;
    _notify();
  }

  void dismissBreathe() {
    breathePrompt = false;
    _notify();
  }

  Future<void> startAudio() => voice.startAudio();

  // ---- Listener -------------------------------------------------------------------

  Future<void> raiseHand() async {
    final up = !handRaised;
    _handOverride = up;
    _notify();
    final ok = await _try(() => repo.stage(spaceId, 'hand', up: up));
    if (!ok) {
      _handOverride = null;
      _notify();
      return;
    }
    up
        ? _toast((l) => l.t('handRaised', {'name': l.name(host)}), Icons.front_hand_rounded)
        : _toast((l) => l.t('handLowered'), Icons.front_hand_outlined);
  }

  Future<void> acceptInvite() async {
    majlisTrace('tap: join the stage');
    if (!await _micAllowed()) {
      declineInvite();
      return;
    }
    _accepting = true;
    inviteDismissed = true;
    _notify();
    final ok = await _try(() => repo.stage(spaceId, 'accept'));
    if (!ok) _accepting = false;
    // The mic opens when LiveKit confirms the new permission (_onVoice),
    // or here if that already arrived. Only one of the two runs.
    if (ok && voice.canSpeak && _accepting) {
      _accepting = false;
      await _openMic(announce: true);
    }
  }

  void declineInvite() {
    inviteDismissed = true;
    _notify();
    repo.stage(spaceId, 'decline').catchError((_) {});
  }

  Future<void> toggleMic() async {
    final on = !micOn;
    majlisTrace('tap: mic ${on ? 'on' : 'off'}');
    if (on && !await _micAllowed()) return;
    _wantMic = on;
    try {
      await voice.setMic(on);
    } catch (e) {
      _wantMic = micOn;
      debugPrint('Majlis mic failed: $e');
    }
    if (micOn) spoke = true;
    _toast((l) => l.t(micOn ? 'micOn' : 'micOff'), micOn ? Icons.mic_rounded : Icons.mic_off_rounded);
  }

  Future<void> leaveStage() async {
    _leavingStage = true;
    _wantMic = false;
    await voice.setMic(false).catchError((_) {});
    final ok = await _try(() => repo.stage(spaceId, 'leave'));
    if (!ok) _leavingStage = false;
    if (ok) _toast((l) => l.t('backToListening'), Icons.headphones_rounded);
  }

  Future<bool> _micAllowed() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) status = await Permission.microphone.request();
    if (status.isGranted) return true;
    _toast(
      (l) => l.t('micDenied'),
      Icons.mic_off_rounded,
      action: status.isPermanentlyDenied ? openAppSettings : null,
      actionLabel: status.isPermanentlyDenied ? (l) => l.t('settings') : null,
      ms: 5000,
    );
    return false;
  }

  Future<void> _openMic({bool announce = false}) async {
    if (!await _micAllowed()) return;
    _wantMic = true;
    try {
      await voice.setMic(true);
      spoke = true;
    } catch (e) {
      _wantMic = false;
      debugPrint('Majlis mic failed: $e');
    }
    if (announce) _toast((l) => l.t('youreOnStage'), Icons.mic_rounded);
    _notify();
  }

  // ---- Host -------------------------------------------------------------------------

  Future<void> inviteToStage(MajlisPerson p) async {
    final ok = await _try(() => repo.stage(spaceId, 'invite', target: p.id));
    if (ok) _toast((l) => l.t('invitedToSpeak', {'name': l.name(p)}), Icons.mic_rounded);
  }

  Future<void> notNow(MajlisPerson p) async {
    final ok = await _try(() => repo.stage(spaceId, 'lower', target: p.id));
    if (ok) _toast((l) => l.t('canRaiseLater', {'name': l.name(p)}), Icons.front_hand_outlined);
  }

  Future<void> moveToListeners(MajlisPerson p) async {
    final ok = await _try(() => repo.stage(spaceId, 'remove', target: p.id));
    if (ok) _toast((l) => l.t('movedToListening', {'name': l.name(p)}), Icons.headphones_rounded);
  }

  Future<void> muteSpeaker(MajlisPerson p) => _try(() => repo.host(spaceId, 'mute', target: p.id));

  Future<void> removePerson(MajlisPerson p) async {
    final ok = await _try(() => repo.host(spaceId, 'remove', target: p.id));
    if (ok) _toast((l) => l.t('removedPerson', {'name': l.name(p)}), Icons.logout_rounded);
  }

  Future<void> muteEveryone() async {
    final ok = await _try(() => repo.host(spaceId, 'muteAll'));
    if (ok) _toast((l) => l.t('everyoneMuted'), Icons.volume_off_rounded);
  }

  Future<void> toggleTurns() async {
    final on = !turns;
    final ok = await _try(() => repo.host(spaceId, 'turns', on: on));
    if (ok) _toast((l) => l.t(on ? 'turnsOn' : 'turnsOff'), Icons.timer_outlined);
  }

  Future<void> nextTurn() => _try(() => repo.host(spaceId, 'nextTurn'));

  Future<void> pin(String text) async {
    final ok = await _try(() => repo.host(spaceId, 'pin', text: text));
    if (ok) _toast((l) => l.t('pinnedToast'), Icons.push_pin_rounded);
  }

  Future<void> pinWhisper(MajlisWhisper w) async {
    final ok = await _try(() => repo.host(spaceId, 'pin', whisperId: w.id));
    if (ok) _toast((l) => l.t('pinnedToast'), Icons.push_pin_rounded);
  }

  Future<void> unpin() async {
    final ok = await _try(() => repo.host(spaceId, 'pin'));
    if (ok) _toast((l) => l.t('unpinned'), Icons.push_pin_outlined);
  }

  void breatheTogether() {
    voice.send('majlis.breathe', {});
    startBreathing(together: true);
  }

  Future<void> endSpace() async {
    final ok = await _try(() => repo.host(spaceId, 'end'));
    if (ok) _close(null);
  }

  void _turnTick() {
    _watchConnection();
    final t = turn;
    if (t == null) return;
    _notify();
    final started = t.startedAt;
    if (!isHost || started == null || _advancingTurn) return;
    if (DateTime.now().difference(started).inSeconds >= MajlisCatalog.turnSeconds) {
      _advancingTurn = true;
      repo.host(spaceId, 'nextTurn').whenComplete(() => _advancingTurn = false).catchError((_) {});
    }
  }

  /// LiveKit normally recovers by itself. If it stays stuck on "reconnecting"
  /// while the app is open (seen after Android froze the app in the
  /// background), join again with a fresh token.
  void _watchConnection() {
    if (phase != MajlisRoomPhase.live || _inBackground || _recovering) return;
    if (voice.state != MajlisVoiceState.reconnecting) {
      _reconnectingSeconds = 0;
      return;
    }
    if (++_reconnectingSeconds < 15) return;
    _reconnectingSeconds = 0;
    _recover();
  }

  Future<void> _recover() async {
    _recovering = true;
    majlisTrace('still reconnecting after 15 s, joining again');
    try {
      final j = await repo.join(spaceId: spaceId);
      if (_disposed || phase != MajlisRoomPhase.live) return;
      if (j.status != 'live' || j.token == null) return _close('endedByHost');
      await voice.connect(j.url!, j.token!);
      for (final b in blocked) {
        await voice.muteFor(b, true);
      }
      _wasSpeaker = voice.canSpeak;
      _wantMic = false;
    } on MajlisException catch (e) {
      debugPrint('Majlis rejoin failed: ${e.code}');
      if (e.code == 'space-gone') _close('endedByHost');
      if (e.code == 'removed') _close('removedYou');
    } catch (e) {
      debugPrint('Majlis rejoin failed: $e');
    } finally {
      _recovering = false;
      _notify();
    }
  }

  // ---- Leaving ------------------------------------------------------------------------

  Future<void> leave() async {
    majlisTrace('leave');
    await voice.leave().catchError((_) {});
    _close(null);
  }

  void _close(String? reason) {
    if (phase == MajlisRoomPhase.closed) return;
    majlisTrace('closed (reason: ${reason ?? 'left'})');
    closeReason = reason;
    phase = MajlisRoomPhase.closed;
    _notify();
  }

  MajlisLeaveResult leaveResult() => MajlisLeaveResult(
        spaceTitle: space?.title ?? '',
        sat: DateTime.now().difference(joinedAt),
        teaReceived: teaForMe,
        spoke: spoke,
        hosted: isHost,
        reason: closeReason,
      );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inBackground = state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
    majlisTrace('app ${state.name}');
    // Privacy first: the mic never stays open while Majlis is out of sight.
    // Listening goes on (a foreground service keeps Android from freezing us).
    if (_inBackground && micOn) {
      _pausedMic = true;
      _wantMic = false;
      voice.setMic(false);
    } else if (state == AppLifecycleState.resumed) {
      _reconnectingSeconds = 0;
      if (_pausedMic) {
        _pausedMic = false;
        _toast((l) => l.t('micPaused'), Icons.mic_off_rounded, ms: 4500);
      }
    }
  }

  // ---- Helpers ------------------------------------------------------------------------

  /// Runs a server call; on failure shows the reason and returns false.
  Future<bool> _try(Future<void> Function() fn) async {
    try {
      await fn();
      return true;
    } on MajlisException catch (e) {
      _toast((l) => l.error(e.code), Icons.info_outline_rounded);
    } catch (e) {
      debugPrint('Majlis call failed: $e');
      _toast((l) => l.error('generic'), Icons.info_outline_rounded);
    }
    return false;
  }

  /// Shows a short message at the top of the room.
  void say(String Function(MajlisStrings l) text, IconData icon) => _toast(text, icon);

  void _toast(
    String Function(MajlisStrings l) text,
    IconData icon, {
    VoidCallback? action,
    String Function(MajlisStrings l)? actionLabel,
    int ms = 2800,
  }) {
    toast = MajlisToast(++_id, text, icon, action: action, actionLabel: actionLabel);
    majlisTrace('toast "${text(MajlisStrings('en'))}"');
    _toastTimer?.cancel();
    _toastTimer = Timer(Duration(milliseconds: ms), () {
      toast = null;
      _notify();
    });
    _notify();
  }

  void _later(int ms, VoidCallback fn) {
    late final Timer t;
    t = Timer(Duration(milliseconds: ms), () {
      _timers.remove(t);
      if (!_disposed) fn();
    });
    _timers.add(t);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    voice.removeListener(_onVoice);
    for (final s in _subs) {
      s.cancel();
    }
    for (final t in _timers) {
      t.cancel();
    }
    _toastTimer?.cancel();
    _tick?.cancel();
    _speakHold?.cancel();
    _troubleTimer?.cancel();
    voice.leave().catchError((_) {}).whenComplete(voice.dispose);
    super.dispose();
  }
}
