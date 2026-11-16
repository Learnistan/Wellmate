import '../repositories/homeRepository.dart';

class GetLastCompletedDifferenceUseCase {
  final HomeRepository repository;

  GetLastCompletedDifferenceUseCase(this.repository);

  Future<int?> call() {
    return repository.getLastCompletedDifference();
  }
}