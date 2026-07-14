class UserEntity {
  final String id;
  final String email;
  final bool emailVerified;

  const UserEntity({
    required this.id,
    required this.email,
    required this.emailVerified,
  });
}