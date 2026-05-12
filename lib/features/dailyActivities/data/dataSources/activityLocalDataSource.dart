import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import '../models/activityLogModel.dart';
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

  // INSERT ACTIVITY LOG
  Future<void> insertActivityLog(ActivityLogModel log) async {
    final db = await dbHelper.database;

    await db.insert(
      'activity_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // GET LOGS FOR AN ACTIVITY
  Future<List<ActivityLogModel>> getActivityLogs(int activityId) async {
    final db = await dbHelper.database;

    final result = await db.query(
      'activity_logs',
      where: 'activity_id = ?',
      whereArgs: [activityId],
      orderBy: 'date DESC',
    );

    return result.map((e) => ActivityLogModel.fromMap(e)).toList();
  }

  // CHECK TODAY COMPLETED
  Future<bool> isActivityCompletedToday(int activityId) async {
    final db = await dbHelper.database;

    final today = DateTime.now().toIso8601String().split('T').first;

    final result = await db.query(
      'activity_logs',
      where: 'activity_id = ? AND date = ?',
      whereArgs: [activityId, today],
    );

    return result.isNotEmpty;
  }

  Future<int> getTodayHydrationGlasses() async {
    final db = await dbHelper.database;

    final today = DateTime.now().toIso8601String().split('T').first;

    final result = await db.query(
      'activity_logs',
      where: 'activity_id = ? AND date = ?',
      whereArgs: [3, today],
      limit: 1,
    );

    // No record today
    if (result.isEmpty) {
      return 0;
    }

    // Get value column
    final value = result.first['value'];

    final decoded = jsonDecode(value.toString());

    return decoded['glasses'] ?? 0;
  }
}