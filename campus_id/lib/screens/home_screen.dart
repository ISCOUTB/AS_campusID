import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget{
  const HomeScreen({super.key});

  Widget quickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              children: [
                Icon(icon, size: 32, color: AppTheme.primaryBlue),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus ID'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hola, Moisés 👋',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bienvenido a Campus ID',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        color: AppTheme.successGreen,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estado de acceso',
                            style: TextStyle(color: Colors.black54),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'HABILITADO',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successGreen,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Accesos rápidos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkBlue,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                quickAction(
                  icon: Icons.badge_outlined,
                  title: 'Mi carné',
                  subtitle: 'Ver ID',
                  onTap: () => Navigator.pushNamed(context, '/virtual-id'),
                ),
                const SizedBox(width: 12),
                quickAction(
                  icon: Icons.history,
                  title: 'Historial',
                  subtitle: 'Registros',
                  onTap: () => Navigator.pushNamed(context, '/history'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/virtual-id');
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('Mostrar QR de acceso'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Último acceso',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkBlue,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x1F22A06B),
                  child: Icon(Icons.login, color: AppTheme.successGreen),
                ),
                title: const Text('Entrada'),
                subtitle: const Text('Hoy, 7:58 a. m.'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Permitido',
                    style: TextStyle(
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}