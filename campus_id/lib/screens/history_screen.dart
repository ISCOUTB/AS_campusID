import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/access_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'p. m.' : 'a. m.';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final records = AccessService.records;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Historial'),
      ),
      body: records.isEmpty
          ? const Center(
              child: Text('No hay registros todavía'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final item = records[index];
                final isOk = item.status == 'Permitido';

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (isOk
                              ? AppTheme.successGreen
                              : AppTheme.alertRed)
                          .withValues(alpha: 0.12),
                      child: Icon(
                        isOk ? Icons.check : Icons.warning_amber_rounded,
                        color: isOk
                            ? AppTheme.successGreen
                            : AppTheme.alertRed,
                      ),
                    ),
                    title: Text(item.type),
                    subtitle: Text(_formatTime(item.time)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (isOk
                                ? AppTheme.successGreen
                                : AppTheme.alertRed)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(
                          color: isOk
                              ? AppTheme.successGreen
                              : AppTheme.alertRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}