
abstract class Syncable {
  Future<bool> sync(String uid);
  Future<bool> hasUnsynced(String uid);
  Future<void> restore(String uid);
}