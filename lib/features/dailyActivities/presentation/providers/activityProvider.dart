import 'package:flutter/material.dart';
import 'package:wellmate/features/dailyActivities/domain/useCases/getTodayHydrationGlasses.dart';
import '../../../../core/seed/defaultActivities.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activityLog.dart';
import '../../domain/useCases/addActivity.dart';
import '../../domain/useCases/addActivityLog.dart';
import '../../domain/useCases/getActivity.dart';
import '../../domain/useCases/updateActivity.dart';

class ActivityProvider extends ChangeNotifier {
  final AddActivity addActivity;
  final GetActivities getActivities;
  final UpdateActivity updateActivity;
  final AddActivityLog addActivityLog;
  final GetTodayHydrationGlasses getTodayHydrationGlasses;

  List<Activity> activities = [];

  ActivityProvider({
    required this.addActivity,
    required this.getActivities,
    required this.updateActivity,
    required this.addActivityLog,
    required this.getTodayHydrationGlasses
  });

  bool isLoading = false;
  int hydrationGlasses = 0;

  Future<void> loadActivities() async {
    activities = await getActivities();
    notifyListeners();
  }

  Future<void> createActivity(Activity activity) async {
    await addActivity(activity);
    await loadActivities();
  }

  Future<void> toggleComplete(Activity activity) async {
    final updated = Activity(
      id: activity.id,
      title: activity.title,
      isActive: !activity.isActive,
      duration: activity.duration,
      iconPath: activity.iconPath,
      route: activity.route,
    );

    await updateActivity(updated);
    await loadActivities();
  }

  Future<void> seedIfEmpty() async {
    await loadActivities();

    if (activities.isNotEmpty) return;

    for (final activity in defaultActivities) {
      await addActivity(activity);
    }

    await loadActivities();
  }

  Future<void> saveHydrationLog({
    required int activityId,
    required String value,
  }) async {
    isLoading = true;
    notifyListeners();

    final today = DateTime.now().toIso8601String().split('T').first;

    final log = ActivityLog(
      activityId: activityId,
      date: today,
      value: value,
    );

    await addActivityLog(log);

    await loadTodayHydrationGlasses();

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadTodayHydrationGlasses() async {
    hydrationGlasses = await getTodayHydrationGlasses();

    notifyListeners();
  }
}