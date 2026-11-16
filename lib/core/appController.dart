import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wellmate/core/storage/domain/repository/appStorageRepository.dart';

import '../features/auth/presentation/provider/authProvider.dart';

class AppController extends ChangeNotifier {

  final AppStorageRepository repository;
  static final navigatorKey = GlobalKey<NavigatorState>();

  AppController(this.repository);

  bool? _isFirstLaunch;

  bool? get isFirstLaunch => _isFirstLaunch;

  Future<void> initialize() async {
    // TODO: later from SharedPreferences
    await Future.delayed(const Duration(seconds: 1));

    _isFirstLaunch = await repository.getIsFirstLaunch();

    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _isFirstLaunch = false;
    await repository.setFirstLaunch(false);

    notifyListeners();
  }
}