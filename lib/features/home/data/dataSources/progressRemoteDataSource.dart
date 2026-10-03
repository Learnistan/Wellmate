import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressRemoteDataSource {
  final FirebaseFirestore firestore;
  ProgressRemoteDataSource(this.firestore);

  Future<void> save(String uid, Map<String, dynamic> row) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc(row['journey'] as String)
        .set({
      'currentLevel': row['current_level'],
      'lastCompletedDate': row['last_completed_date'], // copied as-is
      'updatedAt': row['updated_at'] ?? DateTime.now().toIso8601String(),
    }, SetOptions(merge: true))
        .timeout(const Duration(seconds: 10));
  }

  Future<List<Map<String, dynamic>>> getAll(String uid) async {
    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('progress')
        .get()
        .timeout(const Duration(seconds: 5));

    return snapshot.docs.map((d) => {'journey': d.id, ...d.data()}).toList();
  }
}