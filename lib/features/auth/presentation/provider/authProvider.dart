import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wellmate/features/auth/domain/useCases/checkEmailVerification.dart';
import 'package:wellmate/features/auth/domain/useCases/renderVerificationEmail.dart';
import '../../../../core/enums/authfailureType.dart';
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
  AuthFailureType? _error;
  AuthMessageType? _message;

  AuthFailureType? get error => _error;
  AuthMessageType? get message => _message;

  UserEntity? get user => _user;

  bool get isLoading => _isLoading;

  bool get isAuthenticated =>
      _user != null && _user!.emailVerified;

  bool get isVerificationPending => _isVerificationPending;

  bool get verificationEmailSent => _verificationEmailSent;

  String? get pendingEmail => _pendingEmail;

  void _listenToAuthChanges() {
    _authSubscription =
        firebaseAuth.userChanges().listen(
              (firebaseUser) {
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
              _user = null;
              _pendingEmail = firebaseUser.email;
              _isVerificationPending = true;
            }

            _isLoading = false;
            notifyListeners();
          },
          onError: (Object error) {
            _isLoading = false;
            _error = _mapError(error);
            notifyListeners();
          },
        );
  }

  Future<bool> login(
      String email,
      String password,
      ) async {
    _startLoading();

    try {
      final result = await signInUseCase(email, password);

      _user = result;
      _pendingEmail = null;
      _isVerificationPending = false;
      _verificationEmailSent = false;

      return true;
    } on AuthException catch (error) {
      if (error.type == AuthFailureType.emailNotVerified) {
        final firebaseUser = firebaseAuth.currentUser;

        _user = null;
        _pendingEmail = firebaseUser?.email ?? email;
        _isVerificationPending = true;
        _verificationEmailSent = false;
        _message = AuthMessageType.verificationRequired;

        // Return true if your router interprets this as:
        // "authentication operation handled; go to verify page".
        return true;
      }

      _error = error.type;
      return false;
    } catch (error) {
      _error = AuthFailureType.unknown;
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

      _user = null;
      _pendingEmail = result.email;
      _isVerificationPending = true;
      _verificationEmailSent = true;
      _message = AuthMessageType.verificationEmailSent;

      return true;
    } on AuthException catch (error) {
      _error = error.type;
      return false;
    } catch (error) {
      _error = AuthFailureType.unknown;
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
        _error = AuthFailureType.emailNotVerified;
        return false;
      }

      _user = verifiedUser;
      _pendingEmail = null;
      _isVerificationPending = false;
      _verificationEmailSent = false;
      _message = AuthMessageType.verificationSuccessful;

      return true;
    } on AuthException catch (error) {
      _error = error.type;
      return false;
    } catch (error) {
      _error = AuthFailureType.unknown;
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
      _message = AuthMessageType.newVerificationEmailSent;

      return true;
    } on AuthException catch (error) {
      _error = error.type;
      return false;
    } catch (error) {
      _error = AuthFailureType.unknown;
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
    } on AuthException catch (error) {
      _error = error.type;
    } catch (_) {
      _error = AuthFailureType.unknown;
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

  AuthFailureType _mapError(Object error) {
    if (error is AuthException) {
      return error.type;
    }

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return AuthFailureType.invalidEmail;

        case 'email-already-in-use':
          return AuthFailureType.emailAlreadyInUse;

        case 'weak-password':
          return AuthFailureType.weakPassword;

        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return AuthFailureType.invalidCredentials;

        case 'user-disabled':
          return AuthFailureType.userDisabled;

        case 'too-many-requests':
          return AuthFailureType.tooManyRequests;

        case 'network-request-failed':
          return AuthFailureType.networkError;

        case 'operation-not-allowed':
          return AuthFailureType.operationNotAllowed;

        default:
          return AuthFailureType.unknown;
      }
    }

    return AuthFailureType.unknown;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}