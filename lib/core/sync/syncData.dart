import 'syncable.dart';

class SyncData {
  final List<Syncable> syncables;

  SyncData(this.syncables);

  Future<bool> call(String uid) async {
    var allOk = true;

    for (final syncable in syncables) {
      final ok = await syncable.sync(uid);
      if (!ok) allOk = false; // keep going, one failure shouldn't block the rest
    }

    return allOk;
  }

  Future<bool> hasUnsynced(String uid) async {
    for (final syncable in syncables) {
      if (await syncable.hasUnsynced(uid)) return true;
    }
    return false;
  }

  Future<void> restore(String uid) async {
    for (final syncable in syncables) {
      try {
        await syncable.restore(uid);
      } catch (_) {} // offline or error: continue without it
    }
  }
}