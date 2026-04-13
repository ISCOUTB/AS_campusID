import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/access_service.dart';
import '../services/auth_service.dart';

class ScanAccessScreen extends StatefulWidget {
  const ScanAccessScreen({super.key});

  @override
  State<ScanAccessScreen> createState() => _ScanAccessScreenState();
}

class _ScanAccessScreenState extends State<ScanAccessScreen> {
  String message = 'Listo para escanear';
  String detail = 'Presiona el botón para simular la lectura del QR';
  bool success = true;

  void _simulateScan() {
    final user = AuthService.currentUser;

    if (user == null) {
      setState(() {
        success = false;
        message = 'Sin usuario';
        detail = 'No hay usuario autenticado para validar.';
      });
      return;
    }

    final record = AccessService.registerScan();

    setState(() {
      success = record.status == 'Permitido';
      message = success ? 'Acceso permitido' : 'Acceso denegado';
      detail = '${record.type} registrada para ${user.name}';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(detail),
        backgroundColor: success
            ? AppTheme.successGreen
            : AppTheme.alertRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner de Acceso'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  success ? Icons.verified_user : Icons.warning_amber_rounded,
                  size: 80,
                  color: success ? AppTheme.successGreen : AppTheme.alertRed,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: success
                        ? AppTheme.successGreen
                        : AppTheme.alertRed,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Text(
                          'Usuario actual',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkBlue,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(user?.name ?? 'Sin usuario'),
                        const SizedBox(height: 6),
                        Text(user?.email ?? 'Sin correo'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _simulateScan,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Simular escaneo QR'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}