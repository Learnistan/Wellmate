import 'package:firebase_auth/firebase_auth.dart';

import '../entities/userEntity.dart';

abstract class AuthRepository {
  Future<UserEntity> signIn(String email, String password);

  Future<UserEntity> signUp(String email, String password);

  Future<void> signOut();

  Future<void> resendVerificationEmail();

  Future<UserEntity?> checkEmailVerification();

  Future<UserCredential> signInWithGoogle();

  Future<void> sendPasswordResetEmail(String email);
}