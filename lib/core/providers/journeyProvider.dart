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
}