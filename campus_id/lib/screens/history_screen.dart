import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final records = [
      {
        'title': 'Entrada',
        'time': '7:58 a. m.',
        'status': 'Permitido',
        'ok': true,
      },
      {
        'title': 'Salida',
        'time': '12:45 p. m.',
        'status': 'Permitido',
        'ok': true,
      },
      {
        'title': 'Intento duplicado',
        'time': '8:02 p. m.',
        'status': 'Denegado',
        'ok': false,
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: records.length,
        itemBuilder: (context, index) {
          final item = records[index];
          final isOk = item['ok'] as bool;

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (isOk
                        ? AppTheme.successGreen
                        : AppTheme.alertRed)
                    .withOpacity(0.12),
                child: Icon(
                  isOk ? Icons.check : Icons.warning_amber_rounded,
                  color: isOk ? AppTheme.successGreen : AppTheme.alertRed,
                ),
              ),
              title: Text(item['title'] as String),
              subtitle: Text(item['time'] as String),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (isOk
                          ? AppTheme.successGreen
                          : AppTheme.alertRed)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item['status'] as String,
                  style: TextStyle(
                    color: isOk ? AppTheme.successGreen : AppTheme.alertRed,
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