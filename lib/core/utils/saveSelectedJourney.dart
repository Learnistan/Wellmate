import 'package:shared_preferences/shared_preferences.dart';

import '../constants/journeysData.dart';

Future<void> saveSelectedJourney(Journeys journey) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(
    'selected_journey',
    journey.name,
  );
}