import '../entities/activity.dart';
import '../repositories/activityRepository.dart';

class GetActivities {
  final ActivityRepository repository;

  GetActivities(this.repository);

  Future<List<Activity>> call() {
    return repository.getActivities();
  }
}