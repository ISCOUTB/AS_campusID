import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/theme/app_theme.dart';
import '../services/access_service.dart';
import '../services/auth_service.dart';
import '../services/qr_service.dart';

class ScanAccessScreen extends StatefulWidget {
  const ScanAccessScreen({super.key});

  @override
  State<ScanAccessScreen> createState() => _ScanAccessScreenState();
}

class _ScanAccessScreenState extends State<ScanAccessScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  bool _scannerPaused = false;

  String message = 'Listo para escanear';
  String detail = 'Alinea el código QR dentro del recuadro';
  bool success = true;

  String? lastStudentName;
  String? lastStudentCode;
  String? lastAccessType;

  void _showProfileDialog(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Perfil del autenticador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${user.name}'),
            const SizedBox(height: 6),
            Text('Código: ${user.code}'),
            const SizedBox(height: 6),
            Text('Área: ${user.program}'),
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

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing || _scannerPaused) return;

    final authenticator = AuthService.currentUser;
    if (authenticator == null) return;

    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    _isProcessing = true;
    _scannerPaused = true;
    await controller.stop();

    final parsed = QrService.parseQrData(code);

    if (parsed == null) {
      setState(() {
        success = false;
        message = 'QR inválido';
        detail = 'No fue posible leer la información del QR.';
        lastStudentName = null;
        lastStudentCode = null;
        lastAccessType = null;
      });
      _isProcessing = false;
      return;
    }

    final record = AccessService.registerScan(
      studentName: parsed['studentName']!,
      studentCode: parsed['studentCode']!,
      authenticatedBy: authenticator.name,
    );

    setState(() {
      success = record.status == 'Permitido';
      message = success ? 'Acceso permitido' : 'Acceso denegado';
      detail =
          '${record.type} registrada para ${record.studentName} (${record.studentCode})';
      lastStudentName = record.studentName;
      lastStudentCode = record.studentCode;
      lastAccessType = record.type;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(detail),
        backgroundColor:
            success ? AppTheme.successGreen : AppTheme.alertRed,
      ),
    );

    _isProcessing = false;
  }

  Future<void> _scanAgain() async {
    setState(() {
      message = 'Listo para escanear';
      detail = 'Alinea el código QR dentro del recuadro';
      success = true;
      lastStudentName = null;
      lastStudentCode = null;
      lastAccessType = null;
      _scannerPaused = false;
    });

    await controller.start();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authenticator = AuthService.currentUser;

    if (authenticator == null) {
      return const Scaffold(
        body: Center(
          child: Text('No hay usuario autenticado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner de Acceso'),
        automaticallyImplyLeading: true,
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
            onSelected: (value) {
              if (value == 'perfil') {
                _showProfileDialog(context, authenticator);
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          const Text(
                            'Autenticador actual',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            authenticator.name,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authenticator.email,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Escanea el QR del estudiante',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Alinea el código dentro del recuadro para registrar entrada o salida',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 320,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: MobileScanner(
                            controller: controller,
                            onDetect: _handleBarcode,
                          ),
                        ),
                        Container(
                          width: 230,
                          height: 230,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 3),
                            borderRadius: BorderRadius.circular(20),
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
                          Icon(
                            success
                                ? Icons.verified_user
                                : Icons.warning_amber_rounded,
                            size: 64,
                            color: success
                                ? AppTheme.successGreen
                                : AppTheme.alertRed,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: success
                                  ? AppTheme.successGreen
                                  : AppTheme.alertRed,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            detail,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (lastStudentName != null) ...[
                            const SizedBox(height: 14),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              lastStudentName!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkBlue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastStudentCode ?? '',
                              style: const TextStyle(color: Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Chip(
                              label: Text(lastAccessType ?? ''),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              SizedBox(
                                width: 180,
                                child: OutlinedButton.icon(
                                  onPressed: _scanAgain,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Escanear otro'),
                                ),
                              ),
                              SizedBox(
                                width: 180,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.home_rounded),
                                  label: const Text('Volver'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await controller.toggleTorch();
                            },
                            icon: const Icon(Icons.flashlight_on),
                            label: const Text('Linterna'),
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
      ),
    );
  }
}