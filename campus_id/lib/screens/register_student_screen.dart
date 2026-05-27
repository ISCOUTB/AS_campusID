import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../services/supabase_service.dart';

class RegisterStudentScreen extends StatefulWidget {
  const RegisterStudentScreen({super.key});

  @override
  State<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends State<RegisterStudentScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController(text: 'T000');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedProgram;

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  Uint8List? _avatarBytes;
  String? _avatarFileName;

  final List<String> _programs = const [
    'Ingeniería Civil',
    'Ingeniería de Sistemas y Computación',
    'Ingeniería Industrial',
    'Ingeniería Electrónica',
    'Ingeniería Eléctrica',
    'Ingeniería Mecánica',
    'Ingeniería Mecatrónica',
    'Ingeniería Biomédica',
    'Ingeniería Naval',
    'Ingeniería Química',
    'Ingeniería Ambiental',
    'Ciencia de Datos',
    'Arquitectura y Diseño',
    'Administración de Empresas',
    'Finanzas y Negocios Internacionales',
    'Contaduría Pública',
    'Derecho',
    'Economía',
    'Ciencia Política y Relaciones Internacionales',
    'Psicología',
    'Comunicación Social',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _normalizeName(String value) {
    return value
        .replaceAll(RegExp(r'[^a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trimLeft();
  }

  String _normalizeStudentCode(String value) {
    var cleaned = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    if (!cleaned.startsWith('T000')) {
      cleaned =
          'T000${cleaned.replaceFirst(RegExp(r'^T000?'), '').replaceFirst(RegExp(r'^T'), '')}';
    }

    if (cleaned.length < 4) {
      cleaned = 'T000';
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

  Future<void> _selectProgram() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ProgramPickerSheet(
          programs: _programs,
          selectedProgram: _selectedProgram,
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedProgram = selected;
      });
    }
  }

  Future<void> _handleRegister() async {
    final fullName = _normalizeName(_nameController.text.trim());
    final studentCode = _normalizeStudentCode(_codeController.text.trim());
    final program = _selectedProgram ?? '';
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (fullName.isEmpty ||
        studentCode.isEmpty ||
        program.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      _showSnackBar('Debes completar todos los campos');
      return;
    }

    if (RegExp(r'\d').hasMatch(fullName)) {
      _showSnackBar('El nombre completo no puede contener números');
      return;
    }

    if (!studentCode.startsWith('T000')) {
      _showSnackBar('El código estudiantil debe empezar con T000');
      return;
    }

    if (studentCode.length <= 4) {
      _showSnackBar('Debes completar correctamente el código estudiantil');
      return;
    }

    if (!email.endsWith('@utb.edu.co')) {
      _showSnackBar('Debes usar un correo institucional @utb.edu.co');
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
          userCode: studentCode,
        );
      }

      await SupabaseService.registerStudent(
        name: fullName,
        code: studentCode,
        program: program,
        email: email,
        avatarUrl: avatarUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Estudiante registrado correctamente'),
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
          backgroundImage:
              _avatarBytes != null ? MemoryImage(_avatarBytes!) : null,
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

  Widget _buildProgramSelector() {
    final hasValue = _selectedProgram != null && _selectedProgram!.isNotEmpty;

    return InkWell(
      onTap: _selectProgram,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasValue
                ? AppTheme.primaryBlue.withValues(alpha: 0.25)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.school_outlined, color: Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasValue ? _selectedProgram! : 'Selecciona tu carrera',
                style: TextStyle(
                  fontSize: 16,
                  color: hasValue ? Colors.black87 : Colors.black54,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppTheme.darkBlue,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de estudiante'),
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
                      'Crear cuenta de estudiante',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Registra tus datos institucionales para usar Campus ID',
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
                      decoration: _decoration(
                        label: 'Nombre completo',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9]'),
                        ),
                        LengthLimitingTextInputFormatter(12),
                      ],
                      onChanged: (value) {
                        final normalized = _normalizeStudentCode(value);
                        if (normalized != value) {
                          _codeController.value = TextEditingValue(
                            text: normalized,
                            selection: TextSelection.collapsed(
                              offset: normalized.length,
                            ),
                          );
                        }
                      },
                      decoration: _decoration(
                        label: 'Código estudiantil',
                        icon: Icons.badge_outlined,
                        hint: 'T00077043',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Programa académico',
                          style: TextStyle(
                            color: _selectedProgram != null
                                ? AppTheme.primaryBlue
                                : Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    _buildProgramSelector(),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _decoration(
                        label: 'Correo institucional',
                        icon: Icons.email_outlined,
                        hint: 'correo@utb.edu.co',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: _decoration(
                        label: 'Contraseña',
                        icon: Icons.lock_outline,
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
                            : const Icon(Icons.person_add_alt_1_rounded),
                        label: Text(
                          _isLoading
                              ? 'Registrando...'
                              : 'Registrar estudiante',
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

class _ProgramPickerSheet extends StatefulWidget {
  final List<String> programs;
  final String? selectedProgram;

  const _ProgramPickerSheet({
    required this.programs,
    required this.selectedProgram,
  });

  @override
  State<_ProgramPickerSheet> createState() => _ProgramPickerSheetState();
}

class _ProgramPickerSheetState extends State<_ProgramPickerSheet> {
  late final TextEditingController _searchController;
  late List<String> _filteredPrograms;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredPrograms = List<String>.from(widget.programs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPrograms(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredPrograms = List<String>.from(widget.programs);
      } else {
        _filteredPrograms = widget.programs
            .where(
              (program) => program.toLowerCase().contains(
                    query.trim().toLowerCase(),
                  ),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 54,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.school_outlined, color: AppTheme.darkBlue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Selecciona tu carrera',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _filterPrograms,
              decoration: InputDecoration(
                hintText: 'Buscar carrera',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _filteredPrograms.isEmpty
                ? const Center(
                    child: Text(
                      'No se encontraron resultados',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _filteredPrograms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final program = _filteredPrograms[index];
                      final isSelected = program == widget.selectedProgram;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.pop(context, program);
                          },
                          child: Ink(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryBlue.withValues(alpha: 0.30)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: isSelected
                                      ? AppTheme.primaryBlue
                                      : Colors.black38,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    program,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}