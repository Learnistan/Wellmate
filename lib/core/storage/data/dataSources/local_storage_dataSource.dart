import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageDataSource {
  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  /// Keys
  static const _firstLaunchKey = 'first_launch';
  static const _isLoggedInKey = 'is_logged_in';

  Future<bool> getIsFirstLaunch() async {
    final prefs = await _prefs;
    return prefs.getBool(_firstLaunchKey) ?? true;
  }

  Future<void> setFirstLaunch(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_firstLaunchKey, value);
  }

  Future<bool> getIsLoggedIn() async {
    final prefs = await _prefs;
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<void> setIsLoggedIn(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_isLoggedInKey, value);
  }
}