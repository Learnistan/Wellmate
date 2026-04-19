import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/userEntity.dart';

class UserModel extends UserEntity {
  UserModel({required String id, required String email})
      : super(id: id, email: email);

  factory UserModel.fromFirebase(User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
    );
  }
}