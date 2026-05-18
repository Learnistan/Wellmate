import '../repositories/homeRepository.dart';

class InitProgressUseCase {
  final HomeRepository repository;

  InitProgressUseCase(this.repository);

  Future<void> call() {
    return repository.initProgressIfNeeded();
  }
}