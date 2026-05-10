import 'package:sqflite/sqflite.dart';
import '../models/activityModel.dart';
import '../../../../core/database/databaseHelper.dart';

class ActivityLocalDataSource {
  final DatabaseHelper dbHelper;

  ActivityLocalDataSource(this.dbHelper);

  Future<void> insertActivity(ActivityModel activity) async {
    final db = await dbHelper.database;

    await db.insert(
      'activities',
      activity.toMap(),
    );
  }

  Future<List<ActivityModel>> getActivities() async {
    final db = await dbHelper.database;

    final result = await db.query('activities');

    return result.map((e) => ActivityModel.fromMap(e)).toList();
  }

  Future<void> updateActivity(ActivityModel activity) async {
    final db = await dbHelper.database;

    await db.update(
      'activities',
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }
}