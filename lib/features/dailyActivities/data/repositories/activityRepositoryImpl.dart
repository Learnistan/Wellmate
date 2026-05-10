import '../../domain/entities/activity.dart';
import '../../domain/repositories/activityRepository.dart';
import '../datasources/activityLocalDataSource.dart';
import '../models/activityModel.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityLocalDataSource localDataSource;

  ActivityRepositoryImpl(this.localDataSource);

  @override
  Future<void> addActivity(Activity activity) async {
    final model = ActivityModel(
      title: activity.title,
      isActive: activity.isActive,
      time: activity.time,
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
      activityId: activity.activityId,
      title: activity.title,
      isActive: activity.isActive,
      time: activity.time,
      iconPath: activity.iconPath,
      route: activity.route,
    );

    await localDataSource.updateActivity(model);
  }
}