import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/pill_service.dart';

/// Card per un cambiamento di dosaggio nello storico
class DosageChangeCard extends StatelessWidget {
  final DosageChangeEntry entry;

  const DosageChangeCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd/MM/yyyy').format(entry.timestamp);
    final timeFormatted = DateFormat('HH:mm').format(entry.timestamp);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: ListTile(
        leading: Icon(Icons.edit_note, color: theme.colorScheme.primary),
        title: Text(entry.pillName, style: theme.textTheme.titleMedium),
        subtitle: RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium,
            children: [
              const TextSpan(text: 'Dosaggio: '),
              TextSpan(
                text: entry.oldDosage,
                style: const TextStyle(decoration: TextDecoration.lineThrough),
              ),
              TextSpan(
                text: ' → ${entry.newDosage}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
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
