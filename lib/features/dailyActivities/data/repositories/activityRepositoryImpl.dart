import '../../domain/entities/activity.dart';
import '../../domain/entities/activityLog.dart';
import '../../domain/repositories/activityRepository.dart';
import '../dataSources/activityLocalDataSource.dart';
import '../models/activityLogModel.dart';
import '../models/activityModel.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityLocalDataSource localDataSource;

  ActivityRepositoryImpl(this.localDataSource);

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
}