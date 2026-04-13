import '../models/user_model.dart';

class AuthService {
  static UserModel? _currentUser;

  static UserModel? get currentUser => _currentUser;

  static bool get isLoggedIn => _currentUser != null;

  static Future<UserModel> loginStudent({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    if (email.isEmpty || password.isEmpty) {
      throw Exception('Debes completar todos los campos');
    }

    if (!email.trim().endsWith('@utb.edu.co')) {
      throw Exception('Debes usar tu correo institucional @utb.edu.co');
    }

    _currentUser = UserModel(
      name: 'Moisés David Cortina',
      code: 'T00077043',
      program: 'Ingeniería de Sistemas',
      email: email.trim(),
      role: UserRole.student,
    );

    return _currentUser!;
  }

  static Future<UserModel> loginAuthenticator({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    if (email.isEmpty || password.isEmpty) {
      throw Exception('Debes completar todos los campos');
    }

    _currentUser = UserModel(
      name: 'Personal de Acceso',
      code: 'AUTH-001',
      program: 'Control de Acceso',
      email: email.trim(),
      role: UserRole.authenticator,
    );

    return _currentUser!;
  }

  static void logout() {
    _currentUser = null;
  }
}