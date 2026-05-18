import '../repositories/activityRepository.dart';

class GetTodayHydrationGlasses {
  final ActivityRepository repository;

  GetTodayHydrationGlasses(this.repository);

  Future<int> call() async {
    return await repository.getTodayHydrationGlasses();
  }
}