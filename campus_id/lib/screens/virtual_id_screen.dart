import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/qr_service.dart';
import '../services/access_service.dart';

class VirtualIdScreen extends StatefulWidget {
  const VirtualIdScreen({super.key});

  @override
  State<VirtualIdScreen> createState() => _VirtualIdScreenState();
}

class _VirtualIdScreenState extends State<VirtualIdScreen> {
  String? qrData;
  DateTime? generatedAt;

  @override
  void initState() {
    super.initState();
    _generateNewQr();
  }

  void _generateNewQr() {
    final user = AuthService.currentUser;
    if (user == null) return;

    setState(() {
      qrData = QrService.generateQrData(
        studentCode: user.code,
        studentName: user.name,
      );
      generatedAt = DateTime.now();
    });
  }

  String _formatGeneratedAt(DateTime? time) {
    if (time == null) return 'No generado';
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
        title: const Text('Mi Carné'),
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
      body: StreamBuilder<bool>(
        stream: AccessService.studentInsideStream(user.code),
        builder: (context, insideSnapshot) {
          final isInside = insideSnapshot.data ?? false;
          final nextAction = isInside ? 'Salida' : 'Entrada';

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 18,
                            offset: Offset(0, 8),
                            color: Colors.black12,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(
                              Icons.badge_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Código: ${user.code}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.program,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              'CARNÉ ACTIVO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 760;

                        if (!isWide) {
                          return Column(
                            children: [
                              _statusCard(
                                title: 'Estado actual',
                                value: isInside
                                    ? 'Dentro del campus'
                                    : 'Fuera del campus',
                                icon: isInside
                                    ? Icons.location_on_rounded
                                    : Icons.logout_rounded,
                                color: isInside
                                    ? Colors.orange
                                    : AppTheme.successGreen,
                              ),
                              const SizedBox(height: 14),
                              _statusCard(
                                title: 'Próximo escaneo',
                                value: nextAction,
                                icon: nextAction == 'Entrada'
                                    ? Icons.login_rounded
                                    : Icons.logout_rounded,
                                color: nextAction == 'Entrada'
                                    ? AppTheme.primaryBlue
                                    : AppTheme.alertRed,
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: _statusCard(
                                title: 'Estado actual',
                                value: isInside
                                    ? 'Dentro del campus'
                                    : 'Fuera del campus',
                                icon: isInside
                                    ? Icons.location_on_rounded
                                    : Icons.logout_rounded,
                                color: isInside
                                    ? Colors.orange
                                    : AppTheme.successGreen,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _statusCard(
                                title: 'Próximo escaneo',
                                value: nextAction,
                                icon: nextAction == 'Entrada'
                                    ? Icons.login_rounded
                                    : Icons.logout_rounded,
                                color: nextAction == 'Entrada'
                                    ? AppTheme.primaryBlue
                                    : AppTheme.alertRed,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 14,
                            offset: Offset(0, 4),
                            color: Colors.black12,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Código QR del estudiante',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tu próximo escaneo registrará: $nextAction',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: nextAction == 'Entrada'
                                  ? AppTheme.primaryBlue
                                  : AppTheme.alertRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.20),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                  color: Colors.black12,
                                ),
                              ],
                            ),
                            child: qrData == null
                                ? const SizedBox(
                                    height: 240,
                                    child: Center(
                                      child: Text('QR no generado'),
                                    ),
                                  )
                                : QrImageView(
                                    data: qrData!,
                                    version: QrVersions.auto,
                                    size: 240,
                                    backgroundColor: Colors.white,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Colors.black,
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Colors.black,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 18,
                                  color: AppTheme.darkBlue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Generado a las ${_formatGeneratedAt(generatedAt)}',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'El QR permanece visible hasta que generes uno nuevo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _generateNewQr,
                                icon: const Icon(Icons.qr_code_2_rounded),
                                label: const Text('Generar nuevo QR'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    qrData = null;
                                    generatedAt = null;
                                  });
                                },
                                icon: const Icon(Icons.visibility_off_outlined),
                                label: const Text('Ocultar QR'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 4),
            color: Colors.black12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}