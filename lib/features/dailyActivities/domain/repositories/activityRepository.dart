import '../entities/activity.dart';
import '../entities/activityLog.dart';

abstract class ActivityRepository {
  Future<void> addActivity(Activity activity);

  Future<List<Activity>> getActivities();

  Future<void> updateActivity(Activity activity);

  Future<void> addActivityLog(ActivityLog log);

  Future<List<ActivityLog>> getActivityLogs(int activityId);

  Future<bool> isActivityCompletedToday(int activityId);

  Future<int> getTodayHydrationGlasses();
}