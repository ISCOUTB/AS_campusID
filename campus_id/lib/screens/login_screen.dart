import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.student;

  @override
  void initState() {
    super.initState();
    _redirectIfSessionExists();
  }

  Future<void> _redirectIfSessionExists() async {
    final restored = await AuthService.restoreSession();

    if (!mounted || !restored) return;

    if (AuthService.isStudent) {
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
      return;
    }

    if (AuthService.isAuthenticator) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/auth-dashboard',
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar('Por favor ingresa tu correo electrónico');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showSnackBar('Por favor ingresa tu contraseña');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedRole == UserRole.student) {
        await AuthService.loginStudent(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
      } else {
        await AuthService.loginAuthenticator(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/auth-dashboard',
          (route) => false,
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final isStudent = _selectedRole == UserRole.student;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 960;

    return Scaffold(
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
              constraints: const BoxConstraints(maxWidth: 1180),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 28,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: isWide
                  ? Row(
                      children: [
                        Expanded(child: _buildBrandPanel()),
                        Expanded(child: _buildLoginPanel(isStudent)),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildMobileBrandHeader(),
                          _buildLoginPanel(isStudent, isMobile: true),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandPanel() {
    return Container(
      padding: const EdgeInsets.all(38),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A6BFF), AppTheme.darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Image.asset(
              'assets/images/image.png',
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Bienvenido/a',
            style: TextStyle(
              color: Colors.white,
              fontSize: 46,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Inicia sesión para acceder a tu campus digital y gestionar el control de acceso institucional.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 20,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFEAF2FF),
                  child: Icon(
                    Icons.shield_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Tu seguridad es nuestra prioridad. Accede de forma segura al prototipo funcional de Campus ID.',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildMobileBrandHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.darkBlue, AppTheme.primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/image.png',
            width: 120,
            height: 120,
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
          const SizedBox(height: 6),
          const Text(
            'Universidad Tecnológica de Bolívar',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildLoginPanel(bool isStudent, {bool isMobile = false}) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isMobile) ...[
            Image.asset(
              'assets/images/image.png',
              width: 128,
              height: 128,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              'Campus ID',
              style: TextStyle(
                color: AppTheme.darkBlue,
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isStudent
                  ? 'Acceso seguro para estudiantes'
                  : 'Portal de autenticación institucional',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
          ],
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _roleButton(
                    label: 'Estudiante',
                    icon: Icons.school_outlined,
                    selected: _selectedRole == UserRole.student,
                    onTap: () {
                      setState(() {
                        _selectedRole = UserRole.student;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _roleButton(
                    label: 'Autenticador',
                    icon: Icons.lock_outline,
                    selected: _selectedRole == UserRole.authenticator,
                    onTap: () {
                      setState(() {
                        _selectedRole = UserRole.authenticator;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText:
                  isStudent ? 'Correo institucional' : 'Correo del personal',
              hintText:
                  isStudent ? 'correo@utb.edu.co' : 'correo del personal',
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              hintText: 'Ingresa tu contraseña',
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
          Row(
            children: [
              Checkbox(
                value: false,
                onChanged: (_) {},
              ),
              const Text(
                'Recordarme',
                style: TextStyle(color: Colors.black54),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleLogin,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(
                _isLoading
                    ? 'Ingresando...'
                    : (isStudent
                        ? 'Ingresar como estudiante'
                        : 'Ingresar como autenticador'),
              ),
            ),
          ),
          if (isStudent) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/register-student');
                },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Registrar estudiante'),
              ),
            ),
          ],
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'o continúa con',
                  style: TextStyle(color: Colors.black45),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _socialButton(
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Google',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _socialButton(
                  icon: Icons.apps_rounded,
                  label: 'Microsoft',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: const [
              Text(
                '¿Necesitas ayuda?',
                style: TextStyle(color: Colors.black54),
              ),
              Text(
                'Contáctanos',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String label,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.primaryBlue),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x220D47A1),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}