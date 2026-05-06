import '../models/user_model.dart';
import 'supabase_service.dart';

class AuthService {
  static UserModel? _currentUser;

  static UserModel? get currentUser => _currentUser;

  static bool get isLoggedIn => _currentUser != null;

  static Future<UserModel> loginStudent({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (email.isEmpty || password.isEmpty) {
      throw Exception('Debes completar todos los campos');
    }

    if (!email.trim().endsWith('@utb.edu.co')) {
      throw Exception('Debes usar tu correo institucional @utb.edu.co');
    }

    final user = await SupabaseService.getUserByEmail(email.trim());

    if (user == null) {
      throw Exception('No se encontró el usuario en la base de datos');
    }

    if (user.role != UserRole.student) {
      throw Exception('Este usuario no pertenece al rol estudiante');
    }

    _currentUser = user;
    return _currentUser!;
  }

  static Future<UserModel> loginAuthenticator({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (email.isEmpty || password.isEmpty) {
      throw Exception('Debes completar todos los campos');
    }

    final user = await SupabaseService.getUserByEmail(email.trim());

    if (user == null) {
      throw Exception('No se encontró el usuario en la base de datos');
    }

    if (user.role != UserRole.authenticator) {
      throw Exception('Este usuario no pertenece al rol autenticador');
    }

    _currentUser = user;
    return _currentUser!;
  }

  static void logout() {
    _currentUser = null;
  }
}