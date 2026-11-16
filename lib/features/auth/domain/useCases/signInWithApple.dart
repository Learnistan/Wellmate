import '../repositories/authRepository.dart';

class SignInWithApple {
  final AuthRepository repository;

  SignInWithApple(this.repository);

  Future<void> call() {
    return repository.signInWithApple();
  }
}