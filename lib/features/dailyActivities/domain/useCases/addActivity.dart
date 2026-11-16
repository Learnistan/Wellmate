import '../entities/activity.dart';
import '../repositories/activityRepository.dart';

class AddActivity {
  final ActivityRepository repository;

  AddActivity(this.repository);

  Future<void> call(Activity activity) {
    return repository.addActivity(activity);
  }
}