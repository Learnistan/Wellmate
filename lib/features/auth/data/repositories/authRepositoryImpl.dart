import '../../domain/entities/userEntity.dart';
import '../../domain/repositories/authRepository.dart';
import '../dataSources/authRemoteDataSource.dart';
import '../models/userModel.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity?> signIn(String email, String password) async {
    final user = await remoteDataSource.signIn(email, password);
    if (user == null) return null;
    return UserModel.fromFirebase(user);
  }

  @override
  Future<UserEntity?> signUp(String email, String password) async {
    final user = await remoteDataSource.signUp(email, password);
    if (user == null) return null;
    return UserModel.fromFirebase(user);
  }

  @override
  Future<void> signOut() async {
    await remoteDataSource.signOut();
  }
}