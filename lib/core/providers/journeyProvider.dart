import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../enums/journeys.dart';

class JourneyProvider extends ChangeNotifier {

  Journeys? selectedJourney;

  Future<void> loadJourney() async {

    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getString('selected_journey');

    if (value != null) {

      selectedJourney = Journeys.values.firstWhere(
            (e) => e.name == value,
      );

      notifyListeners();
    }
  }

  Future<void> changeJourney(Journeys journey) async {

    selectedJourney = journey;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'selected_journey',
      journey.name,
    );

    notifyListeners();
  }

  Future<void> loadSelectedJourney() async {
    final prefs = await SharedPreferences.getInstance();

    final journeyName = prefs.getString('selected_journey');

    if (journeyName == null) {
      selectedJourney = null;
    } else {
      selectedJourney = Journeys.values.firstWhere(
            (journey) => journey.name == journeyName,
      );
    }

    notifyListeners();
  }

  Future<void> saveSelectedJourney(Journeys journey) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'selected_journey',
      journey.name,
    );

    selectedJourney = journey;

    notifyListeners();
  }

  Future<void> clearSelectedJourney() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('selected_journey');

    selectedJourney = null;

    notifyListeners();
  }
}