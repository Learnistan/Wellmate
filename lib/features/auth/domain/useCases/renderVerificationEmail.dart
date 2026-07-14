import '../repositories/authRepository.dart';

class ResendVerificationEmail {
  final AuthRepository repository;

  ResendVerificationEmail(this.repository);

  Future<void> call() {
    return repository.resendVerificationEmail();
  }
}