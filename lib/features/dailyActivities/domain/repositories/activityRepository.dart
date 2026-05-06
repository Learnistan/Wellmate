import '../entities/activity.dart';

abstract class ActivityRepository {
  Future<void> addActivity(Activity activity);

  Future<List<Activity>> getActivities();

  Future<void> updateActivity(Activity activity);
}