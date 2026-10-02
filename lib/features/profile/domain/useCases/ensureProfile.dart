import '../repositories/profileRepository.dart';

class EnsureProfile {
  final ProfileRepository repository;
  EnsureProfile(this.repository);

  Future<void> call(String uid, {String? username}) =>
      repository.ensureProfile(uid, username: username);
}