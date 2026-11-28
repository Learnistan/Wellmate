import '../repositories/authRepository.dart';

class DeleteAccount {
  final AuthRepository repository;

  DeleteAccount(this.repository);
  Future<void> call() => repository.deleteAccount();
}