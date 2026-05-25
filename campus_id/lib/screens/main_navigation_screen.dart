import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'virtual_id_screen.dart';
import 'history_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    VirtualIdScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null || !AuthService.isStudent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      });

      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 16,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            height: 76,
            selectedIndex: currentIndex,
            backgroundColor: Colors.white,
            indicatorColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_rounded),
                selectedIcon:
                    Icon(Icons.home_rounded, color: AppTheme.primaryBlue),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.badge_rounded),
                selectedIcon:
                    Icon(Icons.badge_rounded, color: AppTheme.primaryBlue),
                label: 'Carné',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_rounded),
                selectedIcon:
                    Icon(Icons.history_rounded, color: AppTheme.primaryBlue),
                label: 'Historial',
              ),
            ],
          ),
        ),
      ),
    );
  }
}