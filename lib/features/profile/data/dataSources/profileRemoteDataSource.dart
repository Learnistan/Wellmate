import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/enums/journeys.dart';
import '../models/profileModel.dart';

class ProfileRemoteDataSource {
  final FirebaseFirestore firestore;
  ProfileRemoteDataSource(this.firestore);

  static const _subcollections = ['progress', 'daily', 'activity_logs'];

  Future<void> save(ProfileModel p) {
    return firestore
        .collection('users')
        .doc(p.uid)
        .set(p.toRemote(), SetOptions(merge: true))
        .timeout(const Duration(seconds: 10));
  }

  Future<void> updateJourney(String uid, Journeys journey) {
    return firestore.collection('users').doc(uid).set({
      'selectedJourney': journey.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
  }

  Future<ProfileModel?> getProfile(String uid) async {
    final doc = await firestore
        .collection('users')
        .doc(uid)
        .get()
        .timeout(const Duration(seconds: 10));

    if (!doc.exists) return null;
    return ProfileModel.fromRemote(uid, doc.data()!);
  }

  Future<void> deleteProfile(String uid) async {
    final ref = firestore.collection('users').doc(uid);

    await ref
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 10));

    for (final name in _subcollections) {
      await _deleteCollection(ref.collection(name));
    }

    await ref.delete().timeout(const Duration(seconds: 10));
  }

  Future<void> _deleteCollection(
      CollectionReference<Map<String, dynamic>> collection,
      ) async {
    final snapshot = await collection
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 10));

    final docs = snapshot.docs;
    if (docs.isEmpty) return;

    for (var i = 0; i < docs.length; i += 500) {
      final batch = firestore.batch();

      for (final doc in docs.skip(i).take(500)) {
        batch.delete(doc.reference);
      }

      await batch.commit().timeout(const Duration(seconds: 10));
    }
  }
}