import '../entities/userEntity.dart';
import '../repositories/authRepository.dart';

class CheckEmailVerification {
  final AuthRepository repository;

  CheckEmailVerification(this.repository);

  Future<UserEntity?> call() {
    return repository.checkEmailVerification();
  }
}