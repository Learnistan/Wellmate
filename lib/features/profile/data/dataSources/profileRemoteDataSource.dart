import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/enums/journeys.dart';
import '../models/profileModel.dart';

class ProfileRemoteDataSource {
  final FirebaseFirestore firestore;
  ProfileRemoteDataSource(this.firestore);

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
}