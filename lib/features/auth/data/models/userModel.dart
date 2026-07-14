import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/userEntity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.emailVerified,
  });

  factory UserModel.fromFirebase(User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      emailVerified: user.emailVerified,
    );
  }
}