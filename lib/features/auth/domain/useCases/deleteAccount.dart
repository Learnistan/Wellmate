import '../repositories/authRepository.dart';

class DeleteAccount {
  final AuthRepository repository;

  DeleteAccount(this.repository);

  Future<void> call({String? password}) {
    return repository.deleteAccount(
      password: password,
    );
  }
}