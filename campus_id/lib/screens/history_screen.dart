import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/access_service.dart';
import '../services/auth_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'p. m.' : 'a. m.';
    return '$hour:$minute $period';
  }

  void _showProfileDialog(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Perfil del estudiante'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${user.name}'),
            const SizedBox(height: 6),
            Text('Código: ${user.code}'),
            const SizedBox(height: 6),
            Text('Programa: ${user.program}'),
            const SizedBox(height: 6),
            Text('Correo: ${user.email}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final records = AccessService.records;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('No hay usuario autenticado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Historial'),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
            onSelected: (value) {
              if (value == 'perfil') {
                _showProfileDialog(context, user);
              }

              if (value == 'cerrar_sesion') {
                AuthService.logout();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'perfil',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('Perfil'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'cerrar_sesion',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: records.isEmpty
          ? const Center(
              child: Text('No hay registros todavía'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final item = records[index];
                final isOk = item.status == 'Permitido';

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (isOk
                              ? AppTheme.successGreen
                              : AppTheme.alertRed)
                          .withValues(alpha: 0.12),
                      child: Icon(
                        isOk ? Icons.check : Icons.warning_amber_rounded,
                        color: isOk
                            ? AppTheme.successGreen
                            : AppTheme.alertRed,
                      ),
                    ),
                    title: Text('${item.type} - ${item.studentName}'),
                    subtitle: Text(
                      '${item.studentCode} • ${_formatTime(item.time)}\nAutenticado por: ${item.authenticatedBy}',
                    ),
                    isThreeLine: true,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (isOk
                                ? AppTheme.successGreen
                                : AppTheme.alertRed)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(
                          color: isOk
                              ? AppTheme.successGreen
                              : AppTheme.alertRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}