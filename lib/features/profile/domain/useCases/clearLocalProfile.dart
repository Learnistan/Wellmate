import '../repositories/profileRepository.dart';

class ClearLocalProfile {
  final ProfileRepository repository;
  ClearLocalProfile(this.repository);

  Future<void> call() => repository.clearLocalProfile();
}