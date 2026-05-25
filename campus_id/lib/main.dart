import 'package:campus_id/core/theme/config/supabase_config.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/scan_access_screen.dart';
import 'screens/auth_dashboard_screen.dart';
import 'screens/register_student_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const CampusIdApp());
}

class CampusIdApp extends StatelessWidget {
  const CampusIdApp({super.key});

  bool _canAccessStudentArea() {
    return AuthService.isLoggedIn &&
        AuthService.currentUser!.role == UserRole.student;
  }

  bool _canAccessAuthenticatorArea() {
    return AuthService.isLoggedIn &&
        AuthService.currentUser!.role == UserRole.authenticator;
  }

  Route<dynamic> _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus ID',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
          case '/login':
            return _buildRoute(const LoginScreen(), settings);

          case '/register-student':
            return _buildRoute(const RegisterStudentScreen(), settings);

          case '/splash':
            return _buildRoute(const SplashScreen(), settings);

          case '/main':
            if (_canAccessStudentArea()) {
              return _buildRoute(const MainNavigationScreen(), settings);
            }
            return _buildRoute(
              const AccessDeniedScreen(
                title: 'Acceso no permitido',
                message: 'Debes iniciar sesión como estudiante para continuar.',
              ),
              settings,
            );

          case '/auth-dashboard':
            if (_canAccessAuthenticatorArea()) {
              return _buildRoute(const AuthDashboardScreen(), settings);
            }
            return _buildRoute(
              const AccessDeniedScreen(
                title: 'Acceso no permitido',
                message:
                    'Debes iniciar sesión como autenticador para continuar.',
              ),
              settings,
            );

          case '/scan':
            if (_canAccessAuthenticatorArea()) {
              return _buildRoute(const ScanAccessScreen(), settings);
            }
            return _buildRoute(
              const AccessDeniedScreen(
                title: 'Acceso restringido',
                message: 'Solo el autenticador puede acceder al escáner.',
              ),
              settings,
            );

          default:
            return _buildRoute(
              const AccessDeniedScreen(
                title: 'Ruta no disponible',
                message: 'La página que intentaste abrir no está disponible.',
              ),
              settings,
            );
        }
      },
    );
  }
}

class AccessDeniedScreen extends StatelessWidget {
  final String title;
  final String message;

  const AccessDeniedScreen({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.darkBlue, AppTheme.primaryBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        AppTheme.alertRed.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 42,
                      color: AppTheme.alertRed,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Ir al inicio'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}