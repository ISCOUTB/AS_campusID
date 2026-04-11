import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/virtual_id_screen.dart';

void main() {
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
        '/home': (context) => const HomeScreen(),
        '/virtual-id': (context) => const VirtualIdScreen(),
        '/history': (context) => const HistoryScreen(),
      },
    );
  }
}
