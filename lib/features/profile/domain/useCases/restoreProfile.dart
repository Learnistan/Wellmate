import '../entities/profileEntity.dart';
import '../repositories/profileRepository.dart';

class RestoreProfile {
  final ProfileRepository repository;
  RestoreProfile(this.repository);

  Future<ProfileEntity?> call(String uid) => repository.restoreProfile(uid);
}