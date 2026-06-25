// HOME PROVIDER

import 'package:flutter/material.dart';
import 'package:wellmate/features/dailyActivities/domain/useCases/activateAllActivitiesUseCase.dart';
import 'package:wellmate/features/home/domain/useCases/getLastCompletedDifferenceUseCase.dart';

import '../../../../core/services/notificationService.dart';
import '../../domain/useCases/getProgressUseCase.dart';
import '../../domain/useCases/initProgressUseCase.dart';
import '../../domain/useCases/updateProgressUseCase.dart';

class HomeProvider extends ChangeNotifier {

  final InitProgressUseCase initProgressUseCase;
  final GetLastCompletedDifferenceUseCase
  getLastCompletedDifferenceUseCase;

  final ActivateAllActivitiesUseCase
  activateAllActivitiesUseCase;

  final UpdateProgressUseCase updateProgressUseCase;
  final GetProgressUseCase getProgressUseCase;

  final NotificationService notificationService;

  HomeProvider(
      this.initProgressUseCase,
      this.updateProgressUseCase,
      this.getProgressUseCase,
      this.getLastCompletedDifferenceUseCase,
      this.activateAllActivitiesUseCase,
      this.notificationService
      );

  bool _initialized = false;

  bool get initialized => _initialized;

  int? dayDifference;
  String? lastDate;

  // CURRENT LEVEL
  int _level = 0;

  int get level => _level;

  Future<void> initProgress() async {

    if (_initialized) return;

    await initProgressUseCase();

    _initialized = true;

    await loadLevel();

    notifyListeners();
  }

  // LOAD LEVEL
  Future<void> loadLevel() async {

    final progress = await getProgressUseCase();

    if (progress == null) {
      _level = 0;
    } else {
      _level = progress['current_level'];
      lastDate = progress['last_completed_date'];
    }

    notifyListeners();
  }

  Future<void> increaseLevel() async {

    final progress = await getProgressUseCase();

    if (progress == null) return;

    int currentLevel = progress['current_level'];

    if (currentLevel < 14) {

      currentLevel++;

      await updateProgressUseCase(currentLevel);

      _level = currentLevel;

      notifyListeners();
    }
  }

  Future<bool> getLastCompletedDifference() async {

    dayDifference =
    await getLastCompletedDifferenceUseCase();

    if (dayDifference == 0) {

      return false;

    } else if (dayDifference == 1) {

      await activateAllActivitiesUseCase();

      notifyListeners();

      return true;

    } else if (dayDifference == 2) {

      print("*****second action");

    } else if (dayDifference == 3) {

      print("*****third action");
    }

    notifyListeners();

    return false;
  }

  Future<void> refreshInactivityReminder({required String body, required String title}) async {
    await notificationService.scheduleOneDayNotification(message: body, title: title);
    print("Notification scheduled after 24 hours");
  }
}