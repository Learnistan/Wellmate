import 'package:wellmate/core/utils/timeUtils.dart';

import '../../domain/repositories/homeRepository.dart';
import '../dataSources/homeLocalDataSource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeLocalDataSource local;

  HomeRepositoryImpl(this.local);

  @override
  Future<void> initProgressIfNeeded() async {
    final progress = await local.getProgress();

    if (progress == null) {
      await local.insertInitialProgress();
    }
  }

  @override
  Future<void> updateProgress(int level) {
    return local.updateProgress(level);
  }

  @override
  Future<Map<String, dynamic>?> getProgress() {
    return local.getProgress();
  }

  @override
  Future<int?> getLastCompletedDifference() async {
    final progress = await local.getProgress();

    if (progress == null) return null;

    final lastDate = progress['last_completed_date'];

    if (lastDate == null) return null;

    final difference = TimeUtils().calculateDayDifference(lastDate);

    return difference;
  }

  @override
  Future<void> resetProgress() {
    return local.resetProgress();
  }
}