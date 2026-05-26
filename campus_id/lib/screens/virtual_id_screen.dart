import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/qr_service.dart';

class VirtualIdScreen extends StatefulWidget {
  const VirtualIdScreen({super.key});

  @override
  State<VirtualIdScreen> createState() => _VirtualIdScreenState();
}

class _VirtualIdScreenState extends State<VirtualIdScreen> {
  Timer? _timer;
  String? _qrData;
  String? _issuedAtText;
  int _remainingSeconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateQr() {
    final user = AuthService.currentUser;
    if (user == null) return;

    final qrData = QrService.generateQrData(
      studentCode: user.code,
      studentName: user.name,
    );

    final parsed = QrService.parseQrData(qrData);
    final issuedAtText = parsed?['issuedAt'];

    setState(() {
      _qrData = qrData;
      _issuedAtText = issuedAtText;
      _remainingSeconds =
          issuedAtText == null ? 0 : QrService.remainingSeconds(issuedAtText);
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_issuedAtText == null) return;

      final remaining = QrService.remainingSeconds(_issuedAtText!);

      if (!mounted) return;

      setState(() {
        _remainingSeconds = remaining;
      });

      if (remaining <= 0) {
        _timer?.cancel();
      }
    });
  }

  bool get _isExpired {
    if (_issuedAtText == null) return true;
    return QrService.isQrExpired(_issuedAtText!);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null || !AuthService.isStudent) {
      return const Scaffold(
        body: Center(
          child: Text('No hay estudiante autenticado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Carné virtual'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.darkBlue, AppTheme.primaryBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/image.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Campus ID',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.code,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'QR de acceso',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _qrData == null
                            ? 'Genera tu QR cuando vayas a ingresar o salir del campus'
                            : _isExpired
                                ? 'Tu QR venció. Genera uno nuevo para continuar.'
                                : 'Tu QR es válido por $_remainingSeconds segundos',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isExpired ? AppTheme.alertRed : Colors.black54,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: _isExpired && _qrData != null
                                ? AppTheme.alertRed.withValues(alpha: 0.35)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: _qrData == null
                            ? const SizedBox(
                                width: 260,
                                height: 260,
                                child: Center(
                                  child: Text(
                                    'Aún no has generado tu QR',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  Opacity(
                                    opacity: _isExpired ? 0.35 : 1,
                                    child: QrImageView(
                                      data: _qrData!,
                                      version: QrVersions.auto,
                                      size: 260,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                  if (_isExpired)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.alertRed,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Text(
                                        'QR VENCIDO',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _generateQr,
                          icon: const Icon(Icons.qr_code_rounded),
                          label: Text(
                            _qrData == null || _isExpired
                                ? 'Generar QR'
                                : 'Regenerar QR',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información del estudiante',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkBlue,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _infoRow('Nombre', user.name),
                      _infoRow('Código', user.code),
                      _infoRow('Programa', user.program),
                      _infoRow('Correo', user.email),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.darkBlue,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}