import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellmate/core/sync/syncable.dart';
import 'package:wellmate/core/utils/timeUtils.dart';

import '../../../../core/sync/localClearable.dart';
import '../../domain/repositories/homeRepository.dart';
import '../dataSources/homeLocalDataSource.dart';
import '../dataSources/progressRemoteDataSource.dart';

class HomeRepositoryImpl implements HomeRepository, Syncable, LocalClearable {
  final HomeLocalDataSource local;
  final ProgressRemoteDataSource remote;

  HomeRepositoryImpl(this.local, this.remote);

  @override
  Future<void> initProgressIfNeeded() async {
    final progress = await local.getProgress();

    if (progress == null) {
      await local.insertInitialProgress();
    }
  }

  @override
  Future<void> updateProgress(int level) {
    return local.updateProgress(level);
  }

  @override
  Future<Map<String, dynamic>?> getProgress() {
    return local.getProgress();
  }

  @override
  Future<int?> getLastCompletedDifference() async {
    final progress = await local.getProgress();

    if (progress == null) return null;

    final lastDate = progress['last_completed_date'];

    if (lastDate == null) return null;

    final difference = TimeUtils().calculateDayDifference(lastDate);

    return difference;
  }

  @override
  Future<void> resetProgress() {
    return local.resetProgress();
  }

  @override
  Future<bool> sync(String uid) async {
    try {
      final rows = await local.getUnsyncedProgress();

      for (final row in rows) {
        await remote.save(uid, row);
        await local.markProgressSynced(
          row['journey'] as String,
          row['updated_at'] as String?,
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasUnsynced(String uid) async =>
      (await local.getUnsyncedProgress()).isNotEmpty;

  @override
  Future<void> clearLocal() => local.clearProgress();

  @override
  Future<void> restore(String uid) async {
    if (await local.hasProgress()) return; // never overwrite local data

    final docs = await remote.getAll(uid);
    for (final doc in docs) {
      await local.insertRestoredProgress(doc);
    }
  }
}