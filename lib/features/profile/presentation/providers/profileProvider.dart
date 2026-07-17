import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/journeysData.dart';
import '../../../../core/enums/journeys.dart';
import '../../../../core/models/journeyModel.dart';
import '../../domain/useCases/getActiveJourneysUseCase.dart';

class ProfileProvider extends ChangeNotifier {
  final GetActiveJourneysUseCase getActiveJourneysUseCase;

  ProfileProvider(this.getActiveJourneysUseCase);

  List<String> unlockedJourneyNames = [];

  bool _sleepReminder = false;
  bool _foodReminder = false;
  bool _postureReminder = false;

  TimeOfDay _sleepReminderTime = const TimeOfDay(
    hour: 22,
    minute: 0,
  );

  TimeOfDay _foodReminderTime = const TimeOfDay(
    hour: 13,
    minute: 0,
  );

  TimeOfDay _postureReminderTime = const TimeOfDay(
    hour: 9,
    minute: 0,
  );

  bool get sleepReminder => _sleepReminder;

  bool get foodReminder => _foodReminder;

  bool get postureReminder => _postureReminder;

  TimeOfDay get sleepReminderTime => _sleepReminderTime;

  TimeOfDay get foodReminderTime => _foodReminderTime;

  TimeOfDay get postureReminderTime => _postureReminderTime;

  Future<void> loadProfileData() async {
    await Future.wait([
      loadJourneys(),
      loadReminderSettings(),
    ]);
  }

  Future<void> loadJourneys() async {
    unlockedJourneyNames = await getActiveJourneysUseCase();
    notifyListeners();
  }

  Future<void> loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _sleepReminder = prefs.getBool('sleepReminder') ?? false;
    _foodReminder = prefs.getBool('foodReminder') ?? false;
    _postureReminder = prefs.getBool('postureReminder') ?? false;

    _sleepReminderTime = TimeOfDay(
      hour: prefs.getInt('sleepReminderHour') ?? 22,
      minute: prefs.getInt('sleepReminderMinute') ?? 0,
    );

    _foodReminderTime = TimeOfDay(
      hour: prefs.getInt('foodReminderHour') ?? 13,
      minute: prefs.getInt('foodReminderMinute') ?? 0,
    );

    _postureReminderTime = TimeOfDay(
      hour: prefs.getInt('postureReminderHour') ?? 9,
      minute: prefs.getInt('postureReminderMinute') ?? 0,
    );

    notifyListeners();
  }

  Future<void> setSleepReminder(bool value) async {
    _sleepReminder = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sleepReminder', value);
  }

  Future<void> setFoodReminder(bool value) async {
    _foodReminder = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('foodReminder', value);
  }

  Future<void> setPostureReminder(bool value) async {
    _postureReminder = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('postureReminder', value);
  }

  Future<void> setSleepReminderTime(TimeOfDay time) async {
    _sleepReminderTime = time;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sleepReminderHour', time.hour);
    await prefs.setInt('sleepReminderMinute', time.minute);
  }

  Future<void> setFoodReminderTime(TimeOfDay time) async {
    _foodReminderTime = time;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('foodReminderHour', time.hour);
    await prefs.setInt('foodReminderMinute', time.minute);
  }

  Future<void> setPostureReminderTime(TimeOfDay time) async {
    _postureReminderTime = time;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('postureReminderHour', time.hour);
    await prefs.setInt('postureReminderMinute', time.minute);
  }

  List<MapEntry<Journeys, JourneyModel>> get unlockedJourneys {
    return journeysData.entries.where((entry) {
      return unlockedJourneyNames.contains(entry.key.name);
    }).toList();
  }
}