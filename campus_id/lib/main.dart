import 'package:campus_id/core/theme/config/supabase_config.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/scan_access_screen.dart';
import 'screens/auth_dashboard_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus ID',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/main': (context) => const MainNavigationScreen(),
        '/scan': (context) => const ScanAccessScreen(),
        '/auth-dashboard': (context) => const AuthDashboardScreen(),
      },
    );
  }
}