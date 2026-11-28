import '../../../../core/enums/journeys.dart';
import '../entities/profileEntity.dart';

abstract class ProfileRepository {
  Future<List<String>> getUnlockedJourneyNames();
  Future<void> saveProfile(ProfileEntity profile);
  Future<void> updateSelectedJourney(String uid, Journeys journey);
  Future<void> clearLocal();
  Future<void> deleteProfile(String uid);
  Future<bool> syncProfile(String uid);
  Future<ProfileEntity?> getProfile(String uid);
  Future<void> ensureProfile(String uid, {String? username});
  Future<void> restore(String uid);
}
