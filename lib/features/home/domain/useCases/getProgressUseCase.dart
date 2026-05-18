import '../repositories/homeRepository.dart';

class GetProgressUseCase {
  final HomeRepository repository;

  GetProgressUseCase(this.repository);

  Future<Map<String, dynamic>?> call() {
    return repository.getProgress();
  }
}