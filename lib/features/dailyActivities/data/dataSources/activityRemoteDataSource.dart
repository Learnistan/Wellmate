import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityRemoteDataSource {
  final FirebaseFirestore firestore;
  ActivityRemoteDataSource(this.firestore);

  DocumentReference<Map<String, dynamic>> _doc(String uid, String date) =>
      firestore.collection('users').doc(uid).collection('daily').doc(date);

  Future<void> addCompleted(String uid, String date, List<int> ids) {
    return _doc(uid, date).set({
      'completedActivityIds': FieldValue.arrayUnion(ids),
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
  }

  Future<List<int>> getCompleted(String uid, String date) async {
    final doc = await _doc(uid, date).get().timeout(const Duration(seconds: 5));
    final list = doc.data()?['completedActivityIds'] as List<dynamic>? ?? [];
    return list.map((e) => (e as num).toInt()).toList();
  }
}