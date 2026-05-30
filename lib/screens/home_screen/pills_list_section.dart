import 'package:flutter/material.dart';
import '../../data/app_database.dart';

/// Sezione con la lista di tutte le pillole programmate
class PillsListSection extends StatelessWidget {
  final List<Pill> pills;
  final ValueChanged<Pill> onEdit;
  final ValueChanged<int> onDelete;

  const PillsListSection({
    super.key,
    required this.pills,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.list, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Le tue pillole',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (pills.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Nessuna pillola programmata.\nPremi + per aggiungerne una.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...pills.map((pill) => PillCardWidget(
            pill: pill,
            onEdit: () => onEdit(pill),
            onDelete: () => onDelete(pill.id!),
          )),
      ],
    );
  }
}

class PillCardWidget extends StatelessWidget {
  final Pill pill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PillCardWidget({
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
