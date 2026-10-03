import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import '../../../../core/seed/defaultActivities.dart';
import '../models/activityLogModel.dart';
import '../models/activityModel.dart';
import '../../../../core/database/databaseHelper.dart';

class ActivityLocalDataSource {

  final DatabaseHelper dbHelper;
  String get _today => DateTime.now().toIso8601String().split('T').first;

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
      {
        ...activity.toMap(),
        'completed_on': activity.isActive ? null : _today,
      },
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

  Future<void> ActivateAllActivitiesUseCase() async {
    final db = await dbHelper.database;

    await db.update(
      'activities',
      {'isActive': 1},
    );
  }

  Future<void> clearUserData() async {
    final db = await dbHelper.database;
    await db.delete('activity_logs');
    await db.update('activities', {'isActive': 1, 'completed_on': null});
  }

  Future<List<int>> getCompletedTodayIds() async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'activities',
      columns: ['id'],
      where: 'completed_on = ?',
      whereArgs: [_today],
    );
    return rows.map((r) => r['id'] as int).toList()..sort();
  }

  Future<void> markCompleted(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await dbHelper.database;
    await db.update(
      'activities',
      {'isActive': 0, 'completed_on': _today},
      where: 'id IN (${ids.map((_) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  Future<void> seedDefaultsIfEmpty() async {
    final db = await dbHelper.database;
    final count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM activities')) ?? 0;
    if (count > 0) return;

    for (final a in defaultActivities) {
      await db.insert(
        'activities',
        ActivityModel(
          id: a.id,
          title: a.title,
          isActive: a.isActive,
          duration: a.duration,
          iconPath: a.iconPath,
          route: a.route,
        ).toMap(),
      );
    }
  }
}