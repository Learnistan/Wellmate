import '../entities/activity.dart';
import '../repositories/activityRepository.dart';

class UpdateActivity {
  final ActivityRepository repository;

  UpdateActivity(this.repository);

  Future<void> call(Activity activity) {
    return repository.updateActivity(activity);
  }
}