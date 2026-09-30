import '../../../../core/enums/journeys.dart';
import '../../domain/entities/profileEntity.dart';
import '../../domain/repositories/profileRepository.dart';
import '../dataSources/profileDataSource.dart';
import '../dataSources/profileRemoteDataSource.dart';
import '../models/profileModel.dart';

class ProfileRepositoryImpl implements ProfileRepository {

  final ProfileDataSource local;
  final ProfileRemoteDataSource remote;

  ProfileRepositoryImpl(
    this.local,
    this.remote,
  );

  @override
  Future<List<String>> getUnlockedJourneyNames() {
    return local.getUnlockedJourneyNames();
  }

  @override
  Future<void> saveProfile(ProfileEntity profile) async {
    final model = ProfileModel.fromEntity(profile);

    await local.upsert(model, synced: false); // always saved first

    try {
      await remote.save(model);
      await local.markSynced(model.uid);
    } catch (_) {
      // Stays is_synced = 0, the sync step will retry it later.
    }
  }

  @override
  Future<void> updateSelectedJourney(String uid, Journeys journey) async {
    await local.updateJourney(uid, journey);
    try {
      await remote.updateJourney(uid, journey);
      await local.markSynced(uid);
    } catch (_) {}
  }

  @override
  Future<ProfileEntity?> restoreProfile(String uid) async {
    final localProfile = await local.getByUid(uid);
    if (localProfile?.selectedJourney != null) return localProfile;

    try {
      final remoteProfile = await remote.getProfile(uid);
      if (remoteProfile != null) {
        await local.upsert(remoteProfile, synced: true);
        return remoteProfile;
      }
    } catch (_) {}

    return localProfile;
  }

  @override
  Future<void> clearLocalProfile() => local.clearProfile();

  @override
  Future<void> deleteProfile(String uid) => remote.deleteProfile(uid);
}