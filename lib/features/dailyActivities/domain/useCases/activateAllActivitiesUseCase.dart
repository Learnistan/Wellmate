import '../repositories/activityRepository.dart';

class ActivateAllActivitiesUseCase {
  final ActivityRepository repository;

  ActivateAllActivitiesUseCase(this.repository);

  Future<void> call() {
    return repository.activateAllActivitiesUseCase();
  }
}