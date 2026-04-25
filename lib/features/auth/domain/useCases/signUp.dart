import '../entities/userEntity.dart';
import '../repositories/authRepository.dart';

class SignUp {
  final AuthRepository repository;

  SignUp(this.repository);

  Future<UserEntity?> call(String email, String password) {
    return repository.signUp(email, password);
  }
}