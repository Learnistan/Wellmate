import '../entities/profileEntity.dart';
import '../repositories/profileRepository.dart';

class GetProfile {
  final ProfileRepository repository;
  GetProfile(this.repository);

  Future<ProfileEntity?> call(String uid) => repository.getProfile(uid);
}