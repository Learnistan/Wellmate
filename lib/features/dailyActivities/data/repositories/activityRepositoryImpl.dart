import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellmate/core/sync/syncable.dart';

import '../../../../core/sync/localClearable.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activityLog.dart';
import '../../domain/repositories/activityRepository.dart';
import '../dataSources/activityLocalDataSource.dart';
import '../dataSources/activityRemoteDataSource.dart';
import '../models/activityLogModel.dart';
import '../models/activityModel.dart';

class ActivityRepositoryImpl implements ActivityRepository, Syncable, LocalClearable {

  final ActivityLocalDataSource localDataSource;
  final ActivityRemoteDataSource remote;

  ActivityRepositoryImpl(this.localDataSource, this.remote);

  static const _syncedKey = 'last_synced_completions';
  static const _restoredKey = 'daily_restored_for';

  String _today() => DateTime.now().toIso8601String().split('T').first;
  String _signature(List<int> ids) => '${_today()}:${ids.join(',')}';

  @override
  Future<void> addActivity(Activity activity) async {
    final model = ActivityModel(
      title: activity.title,
      isActive: activity.isActive,
      duration: activity.duration,
      iconPath: activity.iconPath,
      route: activity.route,
    );

    await localDataSource.insertActivity(model);
  }

  @override
  Future<List<Activity>> getActivities() async {
    return await localDataSource.getActivities();
  }

  @override
  Future<void> updateActivity(Activity activity) async {
    final model = ActivityModel(
      id: activity.id,
      title: activity.title,
      isActive: activity.isActive,
      duration: activity.duration,
      iconPath: activity.iconPath,
      route: activity.route,
    );

    await localDataSource.updateActivity(model);
  }

  @override
  Future<void> addActivityLog(ActivityLog log) async {
    final model = ActivityLogModel(
      id: log.id,
      activityId: log.activityId,
      date: log.date,
      value: log.value,
    );

    await localDataSource.insertActivityLog(model);
  }

  @override
  Future<List<ActivityLog>> getActivityLogs(int activityId) async {
    return await localDataSource.getActivityLogs(activityId);
  }

  @override
  Future<bool> isActivityCompletedToday(int activityId) async {
    return await localDataSource.isActivityCompletedToday(activityId);
  }

  @override
  Future<int> getTodayHydrationGlasses() async {
    return await localDataSource.getTodayHydrationGlasses();
  }

  @override
  Future<void> activateAllActivitiesUseCase() async {
    return await localDataSource.ActivateAllActivitiesUseCase();
  }

  @override
  Future<void> clearLocal() async {
    await localDataSource.clearUserData();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_syncedKey);
    await prefs.remove(_restoredKey);
  }

  @override
  Future<bool> sync(String uid) async {
    final completedOk = await _syncCompleted(uid);
    final logsOk = await _syncLogs(uid);
    return completedOk && logsOk;
  }

  Future<bool> _syncCompleted(String uid) async {
    try {
      final ids = await localDataSource.getCompletedTodayIds();
      if (ids.isEmpty) return true;

      final prefs = await SharedPreferences.getInstance();
      final signature = _signature(ids);
      if (prefs.getString(_syncedKey) == signature) return true;

      await remote.addCompleted(uid, _today(), ids);
      await prefs.setString(_syncedKey, signature);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _syncLogs(String uid) async {
    try {
      final rows = await localDataSource.getUnsyncedLogs();

      for (final row in rows) {
        await remote.saveLog(uid, row);
        await localDataSource.markLogSynced(
          row['activity_id'] as int,
          row['date'] as String,
          row['updated_at'] as String?,
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasUnsynced(String uid) async {
    if ((await localDataSource.getUnsyncedLogs()).isNotEmpty) return true;

    final ids = await localDataSource.getCompletedTodayIds();
    if (ids.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_syncedKey) != _signature(ids);
  }

  @override
  Future<void> restore(String uid) async {
    // separate try blocks: if one fails, the other still runs
    try {
      await _restoreCompleted(uid);
    } catch (_) {}
    try {
      await _restoreLogs(uid);
    } catch (_) {}
  }

  Future<void> _restoreCompleted(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final marker = '$uid:${_today()}';
    if (prefs.getString(_restoredKey) == marker) return; // once per user per day

    final ids = await remote.getCompleted(uid, _today());
    await prefs.setString(_restoredKey, marker); // only after a successful read
    if (ids.isEmpty) return;

    await localDataSource.seedDefaultsIfEmpty();
    await localDataSource.markCompleted(ids);
    await prefs.setString(
      _syncedKey,
      _signature(await localDataSource.getCompletedTodayIds()),
    );
  }

  Future<void> _restoreLogs(String uid) async {
    if (await localDataSource.hasLogs()) return; // never overwrite local data

    final logs = await remote.getLogs(uid);
    if (logs.isEmpty) return;

    await localDataSource.seedDefaultsIfEmpty(); // activities must exist first
    for (final log in logs) {
      await localDataSource.insertRestoredLog(log);
    }
  }
}