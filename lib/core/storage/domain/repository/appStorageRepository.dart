abstract class AppStorageRepository {
  Future<bool> getIsFirstLaunch();
  Future<void> setFirstLaunch(bool value);

  Future<bool> getIsLoggedIn();
  Future<void> setIsLoggedIn(bool value);
}