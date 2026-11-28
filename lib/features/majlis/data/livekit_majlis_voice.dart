import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

import '../domain/majlis_models.dart';
import '../domain/majlis_voice.dart';

/// Live voice on LiveKit (open source; LiveKit Cloud or self-hosted).
///
/// Tuned for clear speech on weak networks: Opus at 24 kbps ("speech"),
/// DTX (no data while silent), RED (redundant packets survive packet loss),
/// and the phone's echo cancellation, noise suppression and auto gain.
/// Audio plays on the loudspeaker by default, like a room; headphones and
/// Bluetooth take over automatically.
class LiveKitMajlisVoice extends MajlisVoice {
  Room? _room;
  EventsListener<RoomEvent>? _events;
  final _signals = StreamController<MajlisSignal>.broadcast();
  final Set<String> _mutedForMe = {};
  MajlisVoiceState _state = MajlisVoiceState.idle;
  MajlisVoiceEnd _end = MajlisVoiceEnd.none;
  bool _disposed = false;

  /// The LiveKit room, for subclasses (test logging, stats).
  @protected
  Room? get room => _room;

  /// While connected, the room's own connection state is the truth: the
  /// reconnect events are not always paired (seen on Android after the app
  /// came back from the background), which left "Reconnecting" on screen.
  @override
  MajlisVoiceState get state {
    final r = _room;
    if (r != null && (_state == MajlisVoiceState.connected || _state == MajlisVoiceState.reconnecting)) {
      return r.connectionState == ConnectionState.connected
          ? MajlisVoiceState.connected
          : MajlisVoiceState.reconnecting;
    }
    return _state;
  }

  @override
  MajlisLinkQuality get linkQuality => switch (_room?.localParticipant?.connectionQuality) {
        ConnectionQuality.excellent || ConnectionQuality.good => MajlisLinkQuality.good,
        ConnectionQuality.poor => MajlisLinkQuality.weak,
        ConnectionQuality.lost => MajlisLinkQuality.lost,
        _ => MajlisLinkQuality.unknown,
      };

  @override
  MajlisVoiceEnd get end => _end;

  @override
  Stream<MajlisSignal> get signals => _signals.stream;

  @override
  bool get canSpeak => _room?.localParticipant?.permissions.canPublish ?? false;

  @override
  bool get micOn => _room?.localParticipant?.isMicrophoneEnabled() ?? false;

  @override
  bool get canPlayAudio => _room?.canPlaybackAudio ?? true;

  @override
  List<MajlisVoicePeer> get peers {
    final room = _room;
    if (room == null) return const [];
    final out = <MajlisVoicePeer>[];
    final me = room.localParticipant;
    if (me != null) out.add(_peer(me, local: true));
    for (final p in room.remoteParticipants.values) {
      out.add(_peer(p, local: false));
    }
    return out;
  }

  MajlisVoicePeer _peer(Participant p, {required bool local}) => MajlisVoicePeer(
        person: MajlisPerson.fromParticipant(p.identity, p.metadata),
        canSpeak: p.permissions.canPublish,
        speaking: p.isSpeaking,
        micOn: p.isMicrophoneEnabled(),
        isLocal: local,
        joinedAt: p.joinedAt,
      );

  @override
  Future<void> connect(String url, String token) async {
    // A retry starts from a clean room.
    await _events?.dispose();
    _events = null;
    final old = _room;
    _room = null;
    if (old != null) {
      old.removeListener(_changed);
      await old.dispose().then<void>((_) {}, onError: (_) {}).timeout(const Duration(seconds: 4), onTimeout: () {});
    }
    _end = MajlisVoiceEnd.none;
    _set(MajlisVoiceState.connecting);
    final room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: false,
        dynacast: false,
        defaultAudioCaptureOptions: AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
          highPassFilter: true,
          typingNoiseDetection: true,
        ),
        defaultAudioPublishOptions: AudioPublishOptions(
          encoding: AudioEncoding.presetSpeech,
          dtx: true,
          red: true,
        ),
        defaultAudioOutputOptions: AudioOutputOptions(speakerOn: true),
      ),
    );
    _room = room;
    room.addListener(_changed);
    _events = room.createListener()
      ..on<RoomReconnectingEvent>((_) => _set(MajlisVoiceState.reconnecting))
      ..on<RoomAttemptReconnectEvent>((_) => _set(MajlisVoiceState.reconnecting))
      ..on<RoomReconnectedEvent>((_) => _set(MajlisVoiceState.connected))
      ..on<RoomDisconnectedEvent>((e) {
        if (_end == MajlisVoiceEnd.none || _end == MajlisVoiceEnd.left) {
          _end = switch (e.reason) {
            DisconnectReason.clientInitiated => MajlisVoiceEnd.left,
            DisconnectReason.roomDeleted => MajlisVoiceEnd.ended,
            DisconnectReason.participantRemoved => MajlisVoiceEnd.removed,
            DisconnectReason.duplicateIdentity => MajlisVoiceEnd.otherDevice,
            _ => MajlisVoiceEnd.failed,
          };
        }
        _set(MajlisVoiceState.disconnected);
      })
      ..on<TrackSubscribedEvent>((e) {
        if (_mutedForMe.contains(e.participant.identity)) e.publication.unsubscribe();
        _changed();
      })
      ..on<ParticipantConnectedEvent>((_) => _changed())
      ..on<ParticipantDisconnectedEvent>((_) => _changed())
      ..on<ActiveSpeakersChangedEvent>((_) => _changed())
      ..on<TrackMutedEvent>((_) => _changed())
      ..on<TrackUnmutedEvent>((_) => _changed())
      ..on<TrackPublishedEvent>((_) => _changed())
      ..on<TrackUnpublishedEvent>((_) => _changed())
      ..on<LocalTrackPublishedEvent>((_) => _changed())
      ..on<LocalTrackUnpublishedEvent>((_) => _changed())
      ..on<ParticipantPermissionsUpdatedEvent>((_) => _changed())
      ..on<ParticipantMetadataUpdatedEvent>((_) => _changed())
      ..on<AudioPlaybackStatusChanged>((_) => _changed())
      ..on<ParticipantConnectionQualityUpdatedEvent>((_) => _changed())
      ..on<DataReceivedEvent>((e) {
        Map<String, dynamic> data = const {};
        try {
          data = (jsonDecode(utf8.decode(e.data)) as Map).cast<String, dynamic>();
        } catch (_) {}
        if (!_signals.isClosed) _signals.add(MajlisSignal(e.topic ?? '', e.participant?.identity, data));
      });

    try {
      // Generous timeouts: many WellMate users are on slow or shaky mobile data.
      await room.connect(
        url,
        token,
        connectOptions: const ConnectOptions(
          autoSubscribe: true,
          timeouts: Timeouts(
            connection: Duration(seconds: 20),
            debounce: Duration(milliseconds: 20),
            publish: Duration(seconds: 20),
            subscribe: Duration(seconds: 20),
            peerConnection: Duration(seconds: 30),
            iceRestart: Duration(seconds: 20),
          ),
        ),
      );
    } catch (_) {
      _end = MajlisVoiceEnd.failed;
      _set(MajlisVoiceState.disconnected);
      rethrow;
    }
    _set(MajlisVoiceState.connected);
  }

  @override
  Future<void> setMic(bool on) async {
    final me = _room?.localParticipant;
    if (me == null) return;
    await me.setMicrophoneEnabled(on);
    _changed();
  }

  @override
  Future<void> send(String topic, Map<String, dynamic> data, {List<String>? to, bool reliable = true}) async {
    final me = _room?.localParticipant;
    if (me == null || _state != MajlisVoiceState.connected) return;
    await me.publishData(utf8.encode(jsonEncode(data)), reliable: reliable, destinationIdentities: to, topic: topic);
  }

  @override
  Future<void> muteFor(String id, bool muted) async {
    muted ? _mutedForMe.add(id) : _mutedForMe.remove(id);
    final p = _room?.remoteParticipants.values.where((x) => x.identity == id).firstOrNull;
    for (final pub in p?.audioTrackPublications ?? const <RemoteTrackPublication>[]) {
      muted ? await pub.unsubscribe() : await pub.subscribe();
    }
    _changed();
  }

  @override
  Future<void> startAudio() async => _room?.startAudio();

  /// Never hangs: a stuck connection must not keep someone in the room.
  @override
  Future<void> leave() async {
    if (_end == MajlisVoiceEnd.none) _end = MajlisVoiceEnd.left;
    // From here the room is closing, not reconnecting (no banner flash).
    final wasOpen = _state != MajlisVoiceState.disconnected;
    _state = MajlisVoiceState.disconnected;
    final room = _room;
    if (room != null) {
      await room.localParticipant
          ?.setMicrophoneEnabled(false)
          .timeout(const Duration(seconds: 2), onTimeout: () => null)
          .catchError((_) => null);
      await room.disconnect().timeout(const Duration(seconds: 4), onTimeout: () {}).catchError((_) {});
    }
    if (wasOpen) _changed();
  }

  void _set(MajlisVoiceState s) {
    _state = s;
    _changed();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _events?.dispose();
    final room = _room;
    if (room != null) {
      room.removeListener(_changed);
      room
          .disconnect()
          .timeout(const Duration(seconds: 4), onTimeout: () {})
          .catchError((_) {})
          .whenComplete(room.dispose);
    }
    _signals.close();
    super.dispose();
  }
}
