import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/pill_service.dart';

/// Card per un singolo record di assunzione nello storico
class IntakeCard extends StatelessWidget {
  final IntakeRecord record;

  const IntakeCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd/MM/yyyy').format(record.takenAt);
    final timeFormatted = DateFormat('HH:mm').format(record.takenAt);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(record.pill.name, style: theme.textTheme.titleMedium),
        subtitle: Text(record.pill.quantity),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(dateFormatted, style: theme.textTheme.bodySmall),
            Text(timeFormatted,
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
