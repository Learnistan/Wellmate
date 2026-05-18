abstract class HomeRepository {
  Future<void> initProgressIfNeeded();
  Future<void> updateProgress(int level);
  Future<Map<String, dynamic>?> getProgress();
  Future<int?> getLastCompletedDifference();
}