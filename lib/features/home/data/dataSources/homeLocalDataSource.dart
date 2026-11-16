
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/database/databaseHelper.dart';

class HomeLocalDataSource {
  final DatabaseHelper dbHelper;

  HomeLocalDataSource(this.dbHelper);

  Future<Map<String, dynamic>?> getProgress() async {
    final db = await dbHelper.database;

    final prefs = await SharedPreferences.getInstance();
    final selectedJourney = prefs.getString('selected_journey');

    final result = await db.query(
      'progress',
      where: 'journey = ?',
      whereArgs: [selectedJourney]
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  Future<void> insertInitialProgress() async {
    final db = await dbHelper.database;

    final prefs = await SharedPreferences.getInstance();
    final selectedJourney = prefs.getString('selected_journey');

    await db.insert('progress', {
      'current_level': 0,
      'last_completed_date': DateTime.now().toIso8601String().split('T').first,
      'journey': selectedJourney
    });
  }

  Future<void> updateProgress(int level) async {
    final db = await dbHelper.database;

    final prefs = await SharedPreferences.getInstance();
    final selectedJourney = prefs.getString('selected_journey');

    await db.update(
      'progress',
      {
        'current_level': level,
        'last_completed_date': DateTime.now().toIso8601String().split('T').first,
      },
      where: 'journey = ?',
      whereArgs: [selectedJourney]
    );
  }

  Future<void> resetProgress() async {
    final db = await dbHelper.database;

    final prefs = await SharedPreferences.getInstance();
    final selectedJourney = prefs.getString('selected_journey');

    await db.update(
      'progress',
      {
        'current_level': 0,
        'last_completed_date': DateTime.now().toIso8601String().split('T').first,
      },
      where: 'journey = ?',
      whereArgs: [selectedJourney]
    );
  }
}