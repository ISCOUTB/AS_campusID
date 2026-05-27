enum UserRole { student, authenticator }

class UserModel {
  final String name;
  final String code;
  final String program;
  final String email;
  final String? avatarUrl;
  final UserRole role;

  const UserModel({
    required this.name,
    required this.code,
    required this.program,
    required this.email,
    required this.role,
    this.avatarUrl,
  });
}