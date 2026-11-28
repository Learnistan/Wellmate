import '../../../auth/domain/repositories/authRepository.dart';

class ReauthenticateUser {
  final AuthRepository repository;

  ReauthenticateUser(this.repository);

  Future<void> call({String? password}) {
    return repository.reauthenticate(password: password);
  }
}