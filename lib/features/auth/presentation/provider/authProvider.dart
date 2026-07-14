import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wellmate/features/auth/domain/useCases/checkEmailVerification.dart';
import 'package:wellmate/features/auth/domain/useCases/renderVerificationEmail.dart';
import '../../domain/entities/userEntity.dart';
import '../../domain/useCases/signIn.dart';
import '../../domain/useCases/signOut.dart';
import '../../domain/useCases/signUp.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth firebaseAuth;
  final SignIn signInUseCase;
  final SignUp signUpUseCase;
  final SignOut signOutUseCase;
  final ResendVerificationEmail resendVerificationEmailUseCase;
  final CheckEmailVerification checkEmailVerificationUseCase;

  AuthProvider({
    required this.firebaseAuth,
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.resendVerificationEmailUseCase,
    required this.checkEmailVerificationUseCase,
  }) {
    _listenToAuthChanges();
  }

  UserEntity? _user;
  StreamSubscription<User?>? _authSubscription;

  bool _isLoading = true;
  bool _isVerificationPending = false;
  bool _verificationEmailSent = false;

  String? _pendingEmail;
  String? _error;
  String? _message;

  UserEntity? get user => _user;

  bool get isLoading => _isLoading;

  bool get isAuthenticated =>
      _user != null && _user!.emailVerified;

  bool get isVerificationPending => _isVerificationPending;

  bool get verificationEmailSent => _verificationEmailSent;

  String? get pendingEmail => _pendingEmail;

  String? get error => _error;

  String? get message => _message;

  void _listenToAuthChanges() {
    _authSubscription =
        firebaseAuth.userChanges().listen((firebaseUser) {
          if (firebaseUser == null) {
            _user = null;
            _pendingEmail = null;
            _isVerificationPending = false;
          } else if (firebaseUser.emailVerified) {
            _user = UserEntity(
              id: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              emailVerified: true,
            );

            _pendingEmail = null;
            _isVerificationPending = false;
          } else {
            // Firebase has a user, but the application must not
            // consider this person authenticated yet.
            _user = null;
            _pendingEmail = firebaseUser.email;
            _isVerificationPending = true;
          }

          _isLoading = false;
          notifyListeners();
        }, onError: (Object error) {
          _isLoading = false;
          _error = _cleanError(error);
          notifyListeners();
        });
  }

  Future<bool> login(
      String email,
      String password,
      ) async {
    _startLoading();

    try {
      final result = await signInUseCase(email, password);

      if (!result.emailVerified) {
        _user = null;
        _pendingEmail = result.email;
        _isVerificationPending = true;
        _verificationEmailSent = false;

        _message =
        'Please verify your email before continuing.';

        return true;
      }

      _user = result;
      _pendingEmail = null;
      _isVerificationPending = false;
      _verificationEmailSent = false;

      return true;
    } catch (error) {
      _error = _cleanError(error);
      return false;
    } finally {
      _stopLoading();
    }
  }

  Future<bool> register(
      String email,
      String password,
      ) async {
    _startLoading();

    try {
      final result = await signUpUseCase(email, password);

      // Do not set _user here because the account is not verified.
      _user = null;
      _pendingEmail = result.email;
      _isVerificationPending = true;
      _verificationEmailSent = true;

      _message =
      'A verification email has been sent to ${result.email}.';

      return true;
    } catch (error) {
      _error = _cleanError(error);
      return false;
    } finally {
      _stopLoading();
    }
  }

  Future<bool> checkVerification() async {
    _startLoading();

    try {
      final verifiedUser =
      await checkEmailVerificationUseCase();

      if (verifiedUser == null ||
          !verifiedUser.emailVerified) {
        _error =
        'Your email is not verified yet. Open the link in your email, then try again.';

        return false;
      }

      _user = verifiedUser;
      _pendingEmail = null;
      _isVerificationPending = false;
      _verificationEmailSent = false;

      _message = 'Your email has been verified successfully.';

      return true;
    } catch (error) {
      _error = _cleanError(error);
      return false;
    } finally {
      _stopLoading();
    }
  }

  Future<bool> resendVerificationEmail() async {
    _startLoading();

    try {
      await resendVerificationEmailUseCase();

      _verificationEmailSent = true;
      _message = 'A new verification email has been sent.';

      return true;
    } catch (error) {
      _error = _cleanError(error);
      return false;
    } finally {
      _stopLoading();
    }
  }

  Future<void> logout() async {
    _startLoading();

    try {
      await signOutUseCase();

      _user = null;
      _pendingEmail = null;
      _isVerificationPending = false;
      _verificationEmailSent = false;
    } catch (error) {
      _error = _cleanError(error);
    } finally {
      _stopLoading();
    }
  }

  void clearMessages() {
    _error = null;
    _message = null;
    notifyListeners();
  }

  void _startLoading() {
    _isLoading = true;
    _error = null;
    _message = null;
    notifyListeners();
  }

  void _stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}