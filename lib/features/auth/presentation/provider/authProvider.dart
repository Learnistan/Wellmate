import 'package:flutter/material.dart';
import '../../domain/entities/userEntity.dart';
import '../../domain/useCases/signIn.dart';
import '../../domain/useCases/signUp.dart';
import '../../domain/useCases/signOut.dart';

class AuthProvider with ChangeNotifier {
  final SignIn signInUseCase;
  final SignUp signUpUseCase;
  final SignOut signOutUseCase;

  AuthProvider({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
  });

  UserEntity? _user;
  bool _isLoading = false;
  String? _error;

  UserEntity? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// LOGIN
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await signInUseCase(email, password);
      _user = result;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// SIGN UP
  Future<void> register(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await signUpUseCase(email, password);
      _user = result;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// LOGOUT
  Future<void> logout() async {
    await signOutUseCase();
    _user = null;
    notifyListeners();
  }
}