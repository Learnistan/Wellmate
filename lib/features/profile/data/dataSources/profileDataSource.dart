import '../../../../core/database/databaseHelper.dart';

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
}