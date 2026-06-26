import '../repositories/homeRepository.dart';

class ResetJourneyUseCase {
  final HomeRepository repository;

  ResetJourneyUseCase(this.repository);

  Future<void> call() {
    return repository.resetProgress();
  }
}