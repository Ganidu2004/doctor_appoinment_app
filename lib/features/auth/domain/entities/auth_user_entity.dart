class AuthUserEntity {
  final String uid;
  final String email;
  final String? displayName;
  final String? role;

  const AuthUserEntity({
    required this.uid,
    required this.email,
    this.displayName,
    this.role,
  });
}
