import 'majlis_models.dart';

/// Everything Majlis needs from the backend. The app uses
/// FirebaseMajlisRepository (Firestore + Cloud Functions); tests can fake it.
abstract class MajlisRepository {
  /// The signed-in WellMate user, or null.
  String? get uid;

  Stream<MajlisProfile?> watchProfile();
  Future<void> saveVeil({required String veil, required int jewel, required int motif});
  Future<void> setWomenSpaces(bool value);
  Future<void> setBlocked(String uid, bool blocked);
  Future<void> unblockAll();

  Stream<List<MajlisSpace>> watchLive();
  Stream<List<MajlisSpace>> watchScheduled();

  /// Your own live and scheduled spaces (including invite-only ones).
  Stream<List<MajlisSpace>> watchMine();
  Stream<MajlisSpace?> watchSpace(String spaceId);

  /// Ids of scheduled spaces you asked to be reminded about.
  Stream<Set<String>> watchGoing();

  /// Host only.
  Stream<List<MajlisWhisper>> watchWhispers(String spaceId);

  /// Opens a space now, or schedules it when [startsAt] is given.
  Future<({String spaceId, String? inviteCode})> createSpace({
    required String title,
    required String topic,
    required String lang,
    required MajlisAudience audience,
    String? question,
    bool turns = false,
    DateTime? startsAt,
  });

  Future<MajlisJoin> join({String? spaceId, String? code});

  /// hand {up} · accept · decline · leave (yourself); invite · lower · remove (host).
  Future<void> stage(String spaceId, String action, {String? target, bool? up});

  /// start · cancel · end · pin · turns · nextTurn · mute · muteAll · remove.
  Future<void> host(String spaceId, String action, {String? target, String? text, String? whisperId, bool? on});

  Future<void> whisper(String spaceId, String text);
  Future<void> tea(String spaceId, String to);
  Future<int> remind(String spaceId, bool on);
  Future<void> report({String? spaceId, String? target, required String reason, String? note});
}
