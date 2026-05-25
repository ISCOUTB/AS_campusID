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
    if (authenticator == null || !AuthService.isAuthenticator) return;

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

    final record = await AccessService.registerScan(
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

    if (authenticator == null || !AuthService.isAuthenticator) {
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
      canPop: true,
      child: Scaffold(
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
              onSelected: (value) async {
                if (value == 'perfil') {
                  _showProfileDialog(context, authenticator);
                }

                if (value == 'cerrar_sesion') {
                  await AuthService.logout();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
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
              constraints: const BoxConstraints(maxWidth: 980),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Escáner de acceso',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  authenticator.name,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  authenticator.email,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 760;

                        if (!isWide) {
                          return Column(
                            children: [
                              _cameraPanel(),
                              const SizedBox(height: 16),
                              _resultPanel(context),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _cameraPanel(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: _resultPanel(context),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cameraPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
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
            'Escanea el QR del estudiante',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Alinea el código dentro del recuadro para registrar entrada o salida',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 360,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: MobileScanner(
                    controller: controller,
                    onDetect: _handleBarcode,
                  ),
                ),
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              SizedBox(
                width: 180,
                child: OutlinedButton.icon(
                  onPressed: _scanAgain,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Escanear otro'),
                ),
              ),
              SizedBox(
                width: 180,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await controller.toggleTorch();
                  },
                  icon: const Icon(Icons.flashlight_on_rounded),
                  label: const Text('Linterna'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          CircleAvatar(
            radius: 36,
            backgroundColor: (success
                    ? AppTheme.successGreen
                    : AppTheme.alertRed)
                .withValues(alpha: 0.12),
            child: Icon(
              success
                  ? Icons.verified_user_rounded
                  : Icons.warning_amber_rounded,
              size: 38,
              color: success
                  ? AppTheme.successGreen
                  : AppTheme.alertRed,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: success
                  ? AppTheme.successGreen
                  : AppTheme.alertRed,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (lastStudentName != null) ...[
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 14),
            _infoRow(Icons.person_outline, 'Estudiante', lastStudentName!),
            const SizedBox(height: 10),
            _infoRow(Icons.badge_outlined, 'Código', lastStudentCode ?? ''),
            const SizedBox(height: 10),
            _infoRow(
              Icons.swap_horiz_rounded,
              'Movimiento',
              lastAccessType ?? '',
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/auth-dashboard',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.home_rounded),
              label: const Text('Volver al panel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
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
          ),
        ],
      ),
    );
  }
}