import '../entities/profileEntity.dart';
import '../repositories/profileRepository.dart';

class SaveProfile {
  final ProfileRepository repository;
  SaveProfile(this.repository);

  Future<void> call(ProfileEntity profile) => repository.saveProfile(profile);
}