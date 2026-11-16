import '../entities/activityLog.dart';
import '../repositories/activityRepository.dart';

class AddActivityLog {
  final ActivityRepository repository;

  AddActivityLog(this.repository);

  Future<void> call(ActivityLog log) async {
    await repository.addActivityLog(log);
  }
}