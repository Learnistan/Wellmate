import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/userEntity.dart';
import '../../domain/repositories/authRepository.dart';
import '../dataSources/authRemoteDataSource.dart';
import '../models/userModel.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity> signIn(
      String email,
      String password,
      ) async {
    final user = await remoteDataSource.signIn(email, password);

    return UserModel.fromFirebase(user);
  }

  @override
  Future<UserEntity> signUp(
      String email,
      String password,
      ) async {
    final user = await remoteDataSource.signUp(email, password);

    return UserModel.fromFirebase(user);
  }

  @override
  Future<void> signOut() {
    return remoteDataSource.signOut();
  }

  @override
  Future<void> resendVerificationEmail() {
    return remoteDataSource.resendVerificationEmail();
  }

  @override
  Future<UserEntity?> checkEmailVerification() async {
    final user = await remoteDataSource.checkEmailVerification();

    if (user == null) {
      return null;
    }

    return UserModel.fromFirebase(user);
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    return remoteDataSource.signInWithGoogle();
  }
}