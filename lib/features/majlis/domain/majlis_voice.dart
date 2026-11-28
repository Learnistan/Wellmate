import 'package:flutter/foundation.dart';

import 'majlis_models.dart';

enum MajlisVoiceState { idle, connecting, connected, reconnecting, disconnected }

/// Why the voice connection ended.
enum MajlisVoiceEnd { none, left, ended, removed, otherDevice, failed }

/// How well this phone reaches the voice server.
enum MajlisLinkQuality { unknown, good, weak, lost }

/// Someone in the room as the voice service sees them.
class MajlisVoicePeer {
  final MajlisPerson person;
  final bool canSpeak;
  final bool speaking;
  final bool micOn;
  final bool isLocal;
  final DateTime joinedAt;

  const MajlisVoicePeer({
    required this.person,
    required this.canSpeak,
    required this.speaking,
    required this.micOn,
    required this.isLocal,
    required this.joinedAt,
  });

  String get id => person.id;
}

/// A small message sent through the room (reactions, tea, breathe...).
/// [from] is set by the server, so it can be trusted; null means the server.
class MajlisSignal {
  final String topic;
  final String? from;
  final Map<String, dynamic> data;
  const MajlisSignal(this.topic, this.from, this.data);
}

/// The live audio behind a room. Firebase can't carry live voice, so this is
/// LiveKit (LiveKitMajlisVoice). Nothing is ever recorded.
abstract class MajlisVoice extends ChangeNotifier {
  MajlisVoiceState get state;
  MajlisVoiceEnd get end;

  /// Everyone in the room, you included.
  List<MajlisVoicePeer> get peers;

  bool get canSpeak;
  bool get micOn;

  /// This phone's own connection quality (LiveKit measures it every few seconds).
  MajlisLinkQuality get linkQuality => MajlisLinkQuality.unknown;

  /// False when the phone is blocking playback until the user taps (web/iOS edge cases).
  bool get canPlayAudio;

  Stream<MajlisSignal> get signals;

  Future<void> connect(String url, String token);

  /// Turns the microphone on or off. The caller asks for permission first.
  Future<void> setMic(bool on);

  Future<void> send(String topic, Map<String, dynamic> data, {List<String>? to, bool reliable = true});

  /// Stops hearing one person, only on this phone.
  Future<void> muteFor(String id, bool muted);

  Future<void> startAudio();

  Future<void> leave();
}
