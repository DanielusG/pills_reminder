import 'package:flutter/material.dart';
import '../../data/app_database.dart';

/// Card che rappresenta una pillola nella lista
class PillCard extends StatelessWidget {
  final Pill pill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PillCard({
    super.key,
    required this.pill,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.medication, color: Colors.blue),
        title: Text(pill.name, style: theme.textTheme.titleMedium),
        subtitle: Text('${pill.quantity} • ${pill.time}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
              tooltip: 'Modifica',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: onDelete,
              tooltip: 'Elimina',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
