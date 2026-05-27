import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/access_record.dart';
import '../services/access_service.dart';
import '../services/auth_service.dart';

class AuthDashboardScreen extends StatelessWidget {
  const AuthDashboardScreen({super.key});

  void _showProfileDialog(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Perfil del autenticador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) ...[
              Center(
                child: CircleAvatar(
                  radius: 38,
                  backgroundImage: NetworkImage(user.avatarUrl!),
                ),
              ),
              const SizedBox(height: 14),
            ],
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

  String _formatDateTime(DateTime time) {
    final localTime = time.toLocal();
    final hour = localTime.hour > 12
        ? localTime.hour - 12
        : (localTime.hour == 0 ? 12 : localTime.hour);
    final minute = localTime.minute.toString().padLeft(2, '0');
    final period = localTime.hour >= 12 ? 'p. m.' : 'a. m.';
    return '${localTime.day}/${localTime.month}/${localTime.year} - $hour:$minute $period';
  }

  Map<String, int> _buildTodayMetrics(List<AccessRecord> records) {
    final now = DateTime.now();

    final todayRecords = records.where((record) {
      final localTime = record.time.toLocal();
      return localTime.year == now.year &&
          localTime.month == now.month &&
          localTime.day == now.day;
    }).toList();

    final entradas = todayRecords.where((r) => r.type == 'Entrada').length;
    final salidas = todayRecords.where((r) => r.type == 'Salida').length;

    return {
      'total': todayRecords.length,
      'entradas': entradas,
      'salidas': salidas,
    };
  }

  Widget _buildHeaderAvatar(dynamic user) {
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 42,
        backgroundColor: Colors.white.withValues(alpha: 0.18),
        backgroundImage: NetworkImage(user.avatarUrl!),
      );
    }

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Icon(
        Icons.verified_user_rounded,
        size: 42,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null || !AuthService.isAuthenticator) {
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
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel del autenticador'),
          automaticallyImplyLeading: false,
          actions: [
            PopupMenuButton<String>(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white24,
                backgroundImage:
                    user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 18)
                    : null,
              ),
              onSelected: (value) async {
                if (value == 'perfil') {
                  _showProfileDialog(context, user);
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
        body: StreamBuilder<List<AccessRecord>>(
          stream: AccessService.authenticatorLogsStream(user.name),
          builder: (context, snapshot) {
            final records = snapshot.data ?? [];
            final metrics = _buildTodayMetrics(records);
            final lastRecord = records.isNotEmpty ? records.first : null;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
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
                            _buildHeaderAvatar(user),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bienvenido, ${user.name}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    user.email,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _topChip(
                                        icon: Icons.security_rounded,
                                        label: 'Control seguro',
                                      ),
                                      _topChip(
                                        icon: Icons.qr_code_scanner_rounded,
                                        label: 'Escaneo activo',
                                      ),
                                      _topChip(
                                        icon: Icons.bolt_rounded,
                                        label: 'Tiempo real',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _actionCard(
                        context: context,
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'Escanear QR',
                        subtitle:
                            'Inicia el lector para registrar entradas y salidas de estudiantes.',
                        buttonLabel: 'Abrir escáner',
                        onTap: () {
                          Navigator.pushNamed(context, '/scan');
                        },
                        highlighted: true,
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 760;

                          final metricsWidgets = [
                            _metricCard(
                              title: 'Accesos hoy',
                              value: '${metrics['total']}',
                              icon: Icons.assessment_outlined,
                              color: AppTheme.primaryBlue,
                            ),
                            _metricCard(
                              title: 'Entradas hoy',
                              value: '${metrics['entradas']}',
                              icon: Icons.login_rounded,
                              color: AppTheme.successGreen,
                            ),
                            _metricCard(
                              title: 'Salidas hoy',
                              value: '${metrics['salidas']}',
                              icon: Icons.logout_rounded,
                              color: AppTheme.alertRed,
                            ),
                            _metricCard(
                              title: 'Último escaneo',
                              value: lastRecord == null
                                  ? '--'
                                  : lastRecord.studentCode,
                              icon: Icons.history_toggle_off_rounded,
                              color: Colors.orange,
                            ),
                          ];

                          return GridView.count(
                            crossAxisCount: isWide ? 4 : 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: isWide ? 1.15 : 1.2,
                            children: metricsWidgets,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Actividad reciente',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkBlue,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          records.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (records.isEmpty)
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
                          child: const Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 42,
                                color: Colors.black38,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Aún no hay escaneos registrados',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkBlue,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Cuando registres accesos, aparecerán aquí en tiempo real.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: records.take(6).map((record) {
                            final isEntrada = record.type == 'Entrada';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(18),
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
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: (isEntrada
                                            ? AppTheme.successGreen
                                            : AppTheme.alertRed)
                                        .withValues(alpha: 0.12),
                                    child: Icon(
                                      isEntrada
                                          ? Icons.login_rounded
                                          : Icons.logout_rounded,
                                      color: isEntrada
                                          ? AppTheme.successGreen
                                          : AppTheme.alertRed,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          record.studentName,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.darkBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Código: ${record.studentCode}',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDateTime(record.time),
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isEntrada
                                              ? AppTheme.successGreen
                                              : AppTheme.alertRed)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(
                                      record.type,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isEntrada
                                            ? AppTheme.successGreen
                                            : AppTheme.alertRed,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),
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
                              'Datos del autenticador',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkBlue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _dataRow('Nombre', user.name),
                            _dataRow('Código', user.code),
                            _dataRow('Área', user.program),
                            _dataRow('Correo', user.email),
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
      ),
    );
  }

  Widget _actionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: highlighted
            ? const LinearGradient(
                colors: [Color(0xFFF7FAFF), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: highlighted ? null : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlighted
              ? AppTheme.primaryBlue.withValues(alpha: 0.15)
              : Colors.grey.shade200,
        ),
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
          CircleAvatar(
            radius: 30,
            backgroundColor: highlighted
                ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                : Colors.grey.shade100,
            child: Icon(
              icon,
              size: 30,
              color: highlighted ? AppTheme.primaryBlue : AppTheme.darkBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: highlighted
                ? ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(buttonLabel),
                  )
                : OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(buttonLabel),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
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
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBlue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String label, String value) {
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