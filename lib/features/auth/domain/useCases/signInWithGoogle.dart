import '../repositories/authRepository.dart';

class SignInWithGoogle {
  final AuthRepository repository;

  SignInWithGoogle(this.repository);

  Future<void> call() {
    return repository.signInWithGoogle();
  }
}