import 'package:wellmate/core/sync/syncable.dart';

import '../../../../core/enums/journeys.dart';
import '../../domain/entities/profileEntity.dart';
import '../../domain/repositories/profileRepository.dart';
import '../dataSources/profileDataSource.dart';
import '../dataSources/profileRemoteDataSource.dart';
import '../models/profileModel.dart';

class ProfileRepositoryImpl implements ProfileRepository, Syncable {

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
  Future<void> updateSelectedJourney(String uid, Journeys journey) {
    return local.updateJourney(uid, journey); // marks is_synced = 0
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

  @override
  Future<bool> syncProfile(String uid) async {
    try {
      final profile = await local.getUnsynced(uid);
      if (profile == null) return true; // nothing to sync

      await remote.save(profile);
      await local.markSynced(uid);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> sync(String uid) => syncProfile(uid);

  @override
  Future<bool> hasUnsynced(String uid) async =>
      (await local.getUnsynced(uid)) != null;

  @override
  Future<ProfileEntity?> getProfile(String uid) => local.getByUid(uid);

  @override
  Future<void> ensureProfile(String uid, {String? username}) async {
    final existing = await local.getByUid(uid);
    if (existing != null) return;

    await local.upsert(
      ProfileModel(uid: uid, username: username, dateOfBirth: null),
      synced: false, // the normal sync will push it
    );
  }
}