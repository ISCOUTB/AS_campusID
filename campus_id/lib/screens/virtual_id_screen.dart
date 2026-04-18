import 'dart:async';
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
  late String qrData;
  int secondsLeft = 30;
  static const int totalSeconds = 30;
  Timer? countdownTimer;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    _generateNewQr();
    _startTimers();
  }

  void _generateNewQr() {
    final user = AuthService.currentUser;
    if (user == null) return;

    setState(() {
      qrData = QrService.generateQrData(
        studentCode: user.code,
        studentName: user.name,
      );
      secondsLeft = totalSeconds;
    });
  }

  void _startTimers() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (secondsLeft > 1) {
        setState(() {
          secondsLeft--;
        });
      } else {
        _generateNewQr();
      }
    });

    refreshTimer = Timer.periodic(
      const Duration(seconds: totalSeconds),
      (timer) {
        if (!mounted) return;
        _generateNewQr();
      },
    );
  }

  Color _countdownColor() {
    if (secondsLeft <= 10) return AppTheme.alertRed;
    if (secondsLeft <= 20) return Colors.orange;
    return AppTheme.successGreen;
  }

  String _countdownText() {
    if (secondsLeft <= 10) return 'Expira pronto';
    if (secondsLeft <= 20) return 'QR activo';
    return 'QR seguro';
  }

  double _progressValue() {
    return secondsLeft / totalSeconds;
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
  void dispose() {
    countdownTimer?.cancel();
    refreshTimer?.cancel();
    super.dispose();
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

    final isInside = AccessService.isStudentInside(user.code);
    final nextAction = AccessService.nextActionLabel(user.code);

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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_balance,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
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
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'ACTIVO',
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

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _statusBox(
                                title: 'Estado actual',
                                value: isInside ? 'Dentro del campus' : 'Fuera del campus',
                                color: isInside ? Colors.orange : AppTheme.successGreen,
                                icon: isInside ? Icons.location_on : Icons.logout,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statusBox(
                                title: 'Próximo escaneo',
                                value: nextAction,
                                color: nextAction == 'Entrada'
                                    ? AppTheme.primaryBlue
                                    : AppTheme.alertRed,
                                icon: nextAction == 'Entrada'
                                    ? Icons.login
                                    : Icons.logout,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Código QR dinámico',
                          style: TextStyle(
                            fontSize: 20,
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: _countdownColor().withValues(alpha: 0.45),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 12,
                                offset: Offset(0, 4),
                                color: Colors.black12,
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 220,
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
                        const SizedBox(height: 20),
                        Text(
                          _countdownText(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _countdownColor(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: _progressValue(),
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _countdownColor(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            '$secondsLeft s',
                            key: ValueKey(secondsLeft),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: _countdownColor(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Se renueva automáticamente por seguridad',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _generateNewQr,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Actualizar ahora'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBox({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}