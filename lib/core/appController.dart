import 'package:flutter/material.dart';
import 'package:wellmate/core/storage/domain/repository/appStorageRepository.dart';

class AppController extends ChangeNotifier {

  final AppStorageRepository repository;

  AppController(this.repository);

  bool? _isFirstLaunch;
  bool? _isLoggedIn;

  bool? get isFirstLaunch => _isFirstLaunch;
  bool? get isLoggedIn => _isLoggedIn;

  Future<void> initialize() async {
    // TODO: later from SharedPreferences
    await Future.delayed(const Duration(seconds: 1));

    _isFirstLaunch = await repository.getIsFirstLaunch();
    _isLoggedIn = await repository.getIsLoggedIn();

    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _isFirstLaunch = false;
    await repository.setFirstLaunch(false);

    notifyListeners();
  }

  Future<void> login() async {
    _isLoggedIn = true;
    await repository.setIsLoggedIn(true);
    
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    await repository.setIsLoggedIn(false);
    
    notifyListeners();
  }
}