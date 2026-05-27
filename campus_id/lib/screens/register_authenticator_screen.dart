import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../services/supabase_service.dart';

class RegisterAuthenticatorScreen extends StatefulWidget {
  const RegisterAuthenticatorScreen({super.key});

  @override
  State<RegisterAuthenticatorScreen> createState() =>
      _RegisterAuthenticatorScreenState();
}

class _RegisterAuthenticatorScreenState
    extends State<RegisterAuthenticatorScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController(text: 'AUTH-');
  final _areaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminCodeController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isAdminCodeVisible = false;
  bool _isLoading = false;
  Uint8List? _avatarBytes;
  String? _avatarFileName;

  static const String adminSecret = 'UTB-ADMIN-2025';

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _areaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _adminCodeController.dispose();
    super.dispose();
  }

  String _normalizeName(String value) {
    return value
        .replaceAll(RegExp(r'[^a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trimLeft();
  }

  String _normalizeAuthenticatorCode(String value) {
    var cleaned = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9-]'), '');

    if (!cleaned.startsWith('AUTH-')) {
      cleaned =
          'AUTH-${cleaned.replaceFirst(RegExp(r'^AUTH-?'), '').replaceFirst(RegExp(r'^AUTH'), '')}';
    }

    if (cleaned.length < 5) {
      cleaned = 'AUTH-';
    }

    return cleaned;
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      _showSnackBar('No fue posible leer la imagen');
      return;
    }

    setState(() {
      _avatarBytes = file.bytes!;
      _avatarFileName = file.name;
    });
  }

  Future<void> _handleRegister() async {
    final fullName = _normalizeName(_nameController.text.trim());
    final code = _normalizeAuthenticatorCode(_codeController.text.trim());
    final area = _areaController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final adminCode = _adminCodeController.text.trim();

    if (fullName.isEmpty ||
        code.isEmpty ||
        area.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        adminCode.isEmpty) {
      _showSnackBar('Debes completar todos los campos');
      return;
    }

    if (RegExp(r'\d').hasMatch(fullName)) {
      _showSnackBar('El nombre completo no puede contener números');
      return;
    }

    if (!code.startsWith('AUTH-')) {
      _showSnackBar('El código del autenticador debe empezar con AUTH-');
      return;
    }

    if (code.length <= 5) {
      _showSnackBar('Debes completar correctamente el código del autenticador');
      return;
    }

    if (!email.contains('@')) {
      _showSnackBar('Debes ingresar un correo válido');
      return;
    }

    if (adminCode != adminSecret) {
      _showSnackBar('El código admin no es válido');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? avatarUrl;

      if (_avatarBytes != null && _avatarFileName != null) {
        avatarUrl = await SupabaseService.uploadAvatar(
          bytes: _avatarBytes!,
          fileName: _avatarFileName!,
          userCode: code,
        );
      }

      await SupabaseService.registerAuthenticator(
        name: fullName,
        code: code,
        area: area,
        email: email,
        avatarUrl: avatarUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Autenticador registrado correctamente'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.alertRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildAvatarPreview() {
    return Column(
      children: [
        CircleAvatar(
          radius: 46,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: _avatarBytes != null ? MemoryImage(_avatarBytes!) : null,
          child: _avatarBytes == null
              ? const Icon(Icons.person, size: 40, color: Colors.black45)
              : null,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _pickAvatar,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(_avatarBytes == null ? 'Adjuntar foto' : 'Cambiar foto'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de autenticador'),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.darkBlue, AppTheme.primaryBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 640),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/image.png',
                      width: 110,
                      height: 110,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Crear autenticador',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Registra personal autorizado para control de acceso',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildAvatarPreview(),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]"),
                        ),
                      ],
                      onChanged: (value) {
                        final normalized = _normalizeName(value);
                        if (normalized != value) {
                          _nameController.value = TextEditingValue(
                            text: normalized,
                            selection: TextSelection.collapsed(
                              offset: normalized.length,
                            ),
                          );
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
                        LengthLimitingTextInputFormatter(14),
                      ],
                      onChanged: (value) {
                        final normalized = _normalizeAuthenticatorCode(value);
                        if (normalized != value) {
                          _codeController.value = TextEditingValue(
                            text: normalized,
                            selection: TextSelection.collapsed(
                              offset: normalized.length,
                            ),
                          );
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Código del autenticador',
                        hintText: 'AUTH-002',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _areaController,
                      decoration: const InputDecoration(
                        labelText: 'Área o dependencia',
                        hintText: 'Control de Acceso',
                        prefixIcon: Icon(Icons.apartment_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        hintText: 'auth@utb.edu.co',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _adminCodeController,
                      obscureText: !_isAdminCodeVisible,
                      decoration: InputDecoration(
                        labelText: 'Código admin',
                        prefixIcon:
                            const Icon(Icons.admin_panel_settings_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isAdminCodeVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _isAdminCodeVisible = !_isAdminCodeVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleRegister,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.verified_user_outlined),
                        label: Text(
                          _isLoading
                              ? 'Registrando...'
                              : 'Registrar autenticador',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                      child: const Text('Volver al inicio de sesión'),
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
}