import '../repositories/authRepository.dart';

class SendPasswordResetEmail {
  final AuthRepository repository;

  SendPasswordResetEmail(this.repository);

  Future<void> call(String email) {
    return repository.sendPasswordResetEmail(email);
  }
}