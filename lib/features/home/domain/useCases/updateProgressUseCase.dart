import '../repositories/homeRepository.dart';

class UpdateProgressUseCase {
  final HomeRepository repository;

  UpdateProgressUseCase(this.repository);

  Future<void> call(int level) {
    return repository.updateProgress(level);
  }
}