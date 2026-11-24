import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellmate/features/majlis/domain/majlis_models.dart';
import 'package:wellmate/features/majlis/domain/majlis_repository.dart';
import 'package:wellmate/features/majlis/domain/majlis_voice.dart';
import 'package:wellmate/features/majlis/l10n/majlis_strings.dart';
import 'package:wellmate/features/majlis/presentation/controllers/majlis_room_controller.dart';

// The room controller with a fake backend and a fake voice line: what the
// person sees (toasts, stage, closing) for each thing that can happen.

const me = MajlisPerson(id: 'me', veil: 'red_tulip', jewelIndex: 0, motif: 0);
const hostP = MajlisPerson(id: 'host', veil: 'kabul_rain', jewelIndex: 1, motif: 1);
const other = MajlisPerson(id: 'other', veil: 'mulberry', jewelIndex: 2, motif: 2);

MajlisSpace space({
  String hostUid = 'host',
  List<String> speakers = const ['host'],
  List<String> invited = const [],
  bool turns = false,
  MajlisTurn? turn,
}) =>
    MajlisSpace(
      id: 's1',
      title: 'Evening chai',
      topicId: 'chai',
      lang: 'en',
      audience: MajlisAudience.open,
      hostUid: hostUid,
      host: hostUid == 'me' ? me : hostP,
      status: MajlisStatus.live,
      speakerUids: speakers,
      invitedUids: invited,
      turns: turns,
      turn: turn,
    );

class FakeVoice extends MajlisVoice {
  MajlisVoiceState _state = MajlisVoiceState.idle;
  MajlisVoiceEnd _end = MajlisVoiceEnd.none;
  bool speakAllowed = false;
  bool mic = false;
  final List<MajlisVoicePeer> others = [];
  final List<String> sent = [];
  final Map<String, bool> mutedFor = {};
  final signalCtl = StreamController<MajlisSignal>.broadcast();
  int connects = 0;

  @override
  MajlisVoiceState get state => _state;
  @override
  MajlisVoiceEnd get end => _end;
  @override
  bool get canSpeak => speakAllowed;
  @override
  bool get micOn => mic;
  @override
  bool get canPlayAudio => true;
  @override
  Stream<MajlisSignal> get signals => signalCtl.stream;

  @override
  List<MajlisVoicePeer> get peers => [
        MajlisVoicePeer(person: me, canSpeak: speakAllowed, speaking: false, micOn: mic, isLocal: true, joinedAt: DateTime(2026)),
        ...others,
      ];

  @override
  Future<void> connect(String url, String token) async {
    connects++;
    _state = MajlisVoiceState.connected;
    _end = MajlisVoiceEnd.none;
    notifyListeners();
  }

  @override
  Future<void> setMic(bool on) async {
    mic = on;
    notifyListeners();
  }

  @override
  Future<void> send(String topic, Map<String, dynamic> data, {List<String>? to, bool reliable = true}) async =>
      sent.add(topic);

  @override
  Future<void> muteFor(String id, bool muted) async => mutedFor[id] = muted;

  @override
  Future<void> startAudio() async {}

  @override
  Future<void> leave() async {
    if (_end == MajlisVoiceEnd.none) _end = MajlisVoiceEnd.left;
    _state = MajlisVoiceState.disconnected;
    notifyListeners();
  }

  /// What the server or network does.
  void server({bool? canSpeak, bool? micOn, MajlisVoiceState? state, MajlisVoiceEnd? end}) {
    speakAllowed = canSpeak ?? speakAllowed;
    mic = micOn ?? mic;
    _state = state ?? _state;
    _end = end ?? _end;
    notifyListeners();
  }
}

class FakeRepo implements MajlisRepository {
  FakeRepo({this.role = 'listener', this.moderator = false});
  final String role;
  final bool moderator;
  final spaceCtl = StreamController<MajlisSpace?>.broadcast();
  final List<String> calls = [];
  int joins = 0;

  @override
  String? get uid => 'me';

  @override
  Future<MajlisJoin> join({String? spaceId, String? code}) async {
    joins++;
    return MajlisJoin(spaceId: 's1', status: 'live', token: 't', url: 'ws://x', role: role, moderator: moderator);
  }

  @override
  Stream<MajlisSpace?> watchSpace(String spaceId) => spaceCtl.stream;
  @override
  Stream<List<MajlisWhisper>> watchWhispers(String spaceId) => const Stream.empty();

  @override
  Future<void> stage(String spaceId, String action, {String? target, bool? up}) async => calls.add('stage:$action');
  @override
  Future<void> host(String spaceId, String action, {String? target, String? text, String? whisperId, bool? on}) async =>
      calls.add('host:$action');
  @override
  Future<void> whisper(String spaceId, String text) async => calls.add('whisper');
  @override
  Future<void> tea(String spaceId, String to) async => calls.add('tea:$to');
  @override
  Future<void> report({String? spaceId, String? target, required String reason, String? note}) async =>
      calls.add('report:$target');
  @override
  Future<void> setBlocked(String uid, bool blocked) async => calls.add('block:$uid');

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

final en = MajlisStrings('en');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // permission_handler: the microphone is allowed.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (call) async => switch (call.method) {
        'checkPermissionStatus' => 1,
        'requestPermissions' => {7: 1},
        _ => null,
      },
    );
  });

  Future<(MajlisRoomController, FakeVoice, FakeRepo)> room(
    WidgetTester tester, {
    String role = 'listener',
    bool moderator = false,
    bool canSpeak = false,
    MajlisSpace? s,
    Set<String> blocked = const {},
  }) async {
    final voice = FakeVoice()..speakAllowed = canSpeak;
    final repo = FakeRepo(role: role, moderator: moderator);
    final c = MajlisRoomController(repo: repo, voice: voice, spaceId: 's1', me: me, blocked: blocked);
    await c.start();
    repo.spaceCtl.add(s ?? space());
    await tester.pump();
    addTearDown(() async {
      c.dispose();
      await tester.pump(const Duration(seconds: 5));
    });
    return (c, voice, repo);
  }

  String? toast(MajlisRoomController c) => c.toast?.text(en);

  testWidgets('muting yourself says "Mic off", not that the host did it', (tester) async {
    final (c, voice, _) = await room(tester, role: 'speaker', canSpeak: true, s: space(speakers: ['host', 'me']));
    expect(voice.mic, isTrue, reason: 'a speaker starts with the mic open');
    await c.toggleMic();
    await tester.pump();
    expect(toast(c), en.t('micOff'));
  });

  testWidgets('the host muting you says so', (tester) async {
    final (c, voice, _) = await room(tester, role: 'speaker', canSpeak: true, s: space(speakers: ['host', 'me']));
    voice.server(micOn: false);
    await tester.pump();
    expect(toast(c), en.t('hostMutedYou'));
  });

  testWidgets('an invite never opens the mic until "Join the stage" is tapped', (tester) async {
    final (c, voice, repo) = await room(tester);
    repo.spaceCtl.add(space(invited: ['me']));
    voice.signalCtl.add(const MajlisSignal('majlis.invite', null, {}));
    await tester.pump();
    expect(c.invited, isTrue);
    expect(voice.mic, isFalse);

    await c.acceptInvite();
    expect(repo.calls, contains('stage:accept'));
    voice.server(canSpeak: true); // LiveKit grants the new permission
    await tester.pump();
    expect(voice.mic, isTrue);
    expect(toast(c), en.t('youreOnStage'));
  });

  testWidgets('being removed closes the room with the reason', (tester) async {
    final (c, voice, _) = await room(tester);
    voice.server(state: MajlisVoiceState.disconnected, end: MajlisVoiceEnd.removed);
    await tester.pump();
    expect(c.phase, MajlisRoomPhase.closed);
    expect(c.leaveResult().reason, 'removedYou');
  });

  testWidgets('the host ending the space closes it for listeners', (tester) async {
    final (c, _, repo) = await room(tester);
    repo.spaceCtl.add(null);
    await tester.pump();
    expect(c.phase, MajlisRoomPhase.closed);
    expect(c.leaveResult().reason, 'endedByHost');
  });

  testWidgets("other people's reactions float; blocked people's don't", (tester) async {
    final (c, voice, _) = await room(tester, blocked: {'other'});
    voice.signalCtl.add(const MajlisSignal('majlis.react', 'host', {'k': 'love'}));
    voice.signalCtl.add(const MajlisSignal('majlis.react', 'other', {'k': 'love'}));
    voice.signalCtl.add(const MajlisSignal('majlis.react', 'host', {'k': 'not-a-reaction'}));
    await tester.pump();
    expect(c.reactions.length, 1);
    await tester.pump(const Duration(seconds: 3));
    expect(c.reactions, isEmpty, reason: 'reactions float away');
  });

  testWidgets('reactions are sent at most every 350 ms', (tester) async {
    final (c, voice, _) = await room(tester);
    c.react('love');
    c.react('love');
    expect(voice.sent.where((t) => t == 'majlis.react').length, 1);
  });

  testWidgets('going to the background closes the mic and says so on return', (tester) async {
    final (c, voice, _) = await room(tester, role: 'speaker', canSpeak: true, s: space(speakers: ['host', 'me']));
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(voice.mic, isFalse);
    c.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(toast(c), en.t('micPaused'));
    expect(toast(c), isNot(en.t('hostMutedYou')));
  });

  testWidgets('stuck on "Reconnecting" for 15 s: joins again with a fresh token', (tester) async {
    final (c, voice, repo) = await room(tester);
    voice.server(state: MajlisVoiceState.reconnecting);
    await tester.pump(const Duration(seconds: 10));
    expect(c.reconnecting, isTrue);
    expect(repo.joins, 1);
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    expect(repo.joins, 2);
    expect(voice.connects, 2);
    expect(c.reconnecting, isFalse);
  });

  testWidgets('the space ending while you speak closes without a stray toast', (tester) async {
    final (c, voice, _) = await room(tester, role: 'speaker', canSpeak: true, s: space(speakers: ['host', 'me']));
    expect(voice.mic, isTrue);
    voice.server(canSpeak: false, micOn: false, state: MajlisVoiceState.disconnected, end: MajlisVoiceEnd.ended);
    await tester.pump();
    expect(c.phase, MajlisRoomPhase.closed);
    expect(c.closeReason, 'endedByHost');
    expect(toast(c), isNot(anyOf(en.t('movedToListeners'), en.t('hostMutedYou'))));
  });

  testWidgets('a short blip (server mute) shows no "Reconnecting" banner', (tester) async {
    final (c, voice, _) = await room(tester);
    voice.server(state: MajlisVoiceState.reconnecting);
    await tester.pump(const Duration(milliseconds: 40));
    voice.server(state: MajlisVoiceState.connected);
    await tester.pump(const Duration(seconds: 2));
    expect(c.reconnecting, isFalse);
    voice.server(state: MajlisVoiceState.reconnecting);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(c.reconnecting, isFalse);
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.reconnecting, isTrue);
  });

  testWidgets('no rejoin while the app is in the background', (tester) async {
    final (c, voice, repo) = await room(tester);
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    voice.server(state: MajlisVoiceState.reconnecting);
    await tester.pump(const Duration(seconds: 20));
    expect(repo.joins, 1);
  });

  testWidgets("the host's turn timer moves to the next voice after 2 minutes", (tester) async {
    final started = DateTime.now().subtract(const Duration(seconds: 121));
    final (_, _, repo) = await room(tester,
        role: 'host', canSpeak: true, s: space(hostUid: 'me', speakers: ['me', 'other'], turns: true, turn: MajlisTurn('me', started)));
    await tester.pump(const Duration(seconds: 2));
    expect(repo.calls, contains('host:nextTurn'));
  });

  testWidgets('a guide gets the safety tools, a listener does not', (tester) async {
    final (guide, _, _) = await room(tester, moderator: true);
    expect(guide.canModerate, isTrue);
    expect(guide.isHost, isFalse);
    await guide.muteEveryone();
    final (listener, _, _) = await room(tester);
    expect(listener.canModerate, isFalse);
  });

  testWidgets('the host hears about an auto-mute after reports', (tester) async {
    final (c, voice, _) = await room(tester, role: 'host', canSpeak: true, s: space(hostUid: 'me', speakers: ['me']));
    voice.others.add(MajlisVoicePeer(person: other, canSpeak: true, speaking: false, micOn: true, isLocal: false, joinedAt: DateTime(2026)));
    voice.signalCtl.add(const MajlisSignal('majlis.autoMuted', null, {'target': 'other'}));
    await tester.pump();
    expect(toast(c), en.t('autoMuted', {'name': en.name(other)}));
  });
}
