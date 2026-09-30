import '../../../../core/database/databaseHelper.dart';
import '../../../../core/enums/journeys.dart';
import '../models/profileModel.dart';

class ProfileDataSource {
  final DatabaseHelper databaseHelper;

  ProfileDataSource(this.databaseHelper);

  Future<List<String>> getUnlockedJourneyNames() async {
    final db = await databaseHelper.database;

    final result = await db.query(
      'progress',
      columns: ['journey'],
    );

    return result
        .map((e) => e['journey'] as String)
        .toList();
  }

  Future<void> upsert(ProfileModel p, {required bool synced}) async {
    final db = await DatabaseHelper.instance.database;

    final updated = await db.update(
      'profile',
      p.toLocal(synced: synced),
      where: 'remote_id = ?',
      whereArgs: [p.uid],
    );

    if (updated == 0) {
      await db.insert('profile', {
        ...p.toLocal(synced: synced),
        'created_at': DateTime.now().toIso8601String(), // NOT NULL in your table
      });
    }
  }

  Future<void> markSynced(String uid) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('profile', {'is_synced': 1},
        where: 'remote_id = ?', whereArgs: [uid]);
  }

  Future<void> updateJourney(String uid, Journeys journey) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'profile',
      {
        'selected_journey': journey.name,
        'is_synced': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'remote_id = ?',
      whereArgs: [uid],
    );
  }

  Future<ProfileModel?> getByUid(String uid) async {
    final db = await DatabaseHelper.instance.database;

    final rows = await db.query(
      'profile',
      where: 'remote_id = ?',
      whereArgs: [uid],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return ProfileModel.fromLocal(rows.first);
  }
}