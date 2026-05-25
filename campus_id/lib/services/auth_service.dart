import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

class AuthService {
  static const String _sessionEmailKey = 'session_email';
  static const String _sessionRoleKey = 'session_role';

  static UserModel? _currentUser;

  static UserModel? get currentUser => _currentUser;

  static bool get isLoggedIn => _currentUser != null;

  static bool get isStudent =>
      _currentUser != null && _currentUser!.role == UserRole.student;

  static bool get isAuthenticator =>
      _currentUser != null && _currentUser!.role == UserRole.authenticator;

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
    await _persistSession(user);
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
    await _persistSession(user);
    return _currentUser!;
  }

  static Future<void> _persistSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionEmailKey, user.email);
    await prefs.setString(
      _sessionRoleKey,
      user.role == UserRole.student ? 'student' : 'authenticator',
    );
  }

  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_sessionEmailKey);
    final savedRole = prefs.getString(_sessionRoleKey);

    if (savedEmail == null || savedRole == null) {
      _currentUser = null;
      return false;
    }

    final user = await SupabaseService.getUserByEmail(savedEmail);

    if (user == null) {
      await clearSession();
      return false;
    }

    final expectedRole = savedRole == 'student'
        ? UserRole.student
        : UserRole.authenticator;

    if (user.role != expectedRole) {
      await clearSession();
      return false;
    }

    _currentUser = user;
    return true;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionEmailKey);
    await prefs.remove(_sessionRoleKey);
    _currentUser = null;
  }

  static Future<void> logout() async {
    await clearSession();
  }
}