
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
      'journey': selectedJourney,
      'is_synced': 1,
      'updated_at': DateTime.now().toIso8601String(),
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
        'is_synced': 0,
        'updated_at': DateTime.now().toIso8601String(),
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
        'is_synced': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'journey = ?',
      whereArgs: [selectedJourney]
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedProgress() async {
    final db = await dbHelper.database;
    return db.query('progress', where: 'is_synced = 0');
  }

  Future<void> markProgressSynced(String journey, String? updatedAt) async {
    final db = await dbHelper.database;

    // Only mark synced if the row didn't change while we were uploading.
    await db.update(
      'progress',
      {'is_synced': 1},
      where: updatedAt == null
          ? 'journey = ? AND updated_at IS NULL'
          : 'journey = ? AND updated_at = ?',
      whereArgs: updatedAt == null ? [journey] : [journey, updatedAt],
    );
  }

  Future<void> clearProgress() async {
    final db = await dbHelper.database;
    await db.delete('progress');
  }

  Future<bool> hasProgress() async {
    final db = await dbHelper.database;
    final rows = await db.query('progress', limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> insertRestoredProgress(Map<String, dynamic> remote) async {
    final db = await dbHelper.database;

    await db.insert('progress', {
      'journey': remote['journey'],
      'current_level': (remote['currentLevel'] as num?)?.toInt() ?? 0,
      'last_completed_date': remote['lastCompletedDate'], // copied exactly
      'is_synced': 1, // it came from remote, nothing to push
      'updated_at': remote['updatedAt'],
    });
  }
}