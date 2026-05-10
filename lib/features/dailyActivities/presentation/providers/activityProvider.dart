import 'package:flutter/material.dart';
import '../../../../core/seed/defaultActivities.dart';
import '../../domain/entities/activity.dart';
import '../../domain/useCases/addActivity.dart';
import '../../domain/useCases/getActivity.dart';
import '../../domain/useCases/updateActivity.dart';

class ActivityProvider extends ChangeNotifier {
  final AddActivity addActivity;
  final GetActivities getActivities;
  final UpdateActivity updateActivity;

  List<Activity> activities = [];

  ActivityProvider({
    required this.addActivity,
    required this.getActivities,
    required this.updateActivity,
  });

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
}