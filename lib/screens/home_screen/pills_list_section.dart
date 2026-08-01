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

  Widget _buildSubtitle(Pill pill) {
    final count = pill.totalIntakeCount;
    final children = <Widget>[];

    children.add(Text('${pill.quantity} • ${pill.time}'));

    if (count != null && count > 0) {
      final countText = pill.totalDoses != null
          ? '$count/${pill.totalDoses} volte'
          : '$count volte';
      children.add(
        Text(
          countText,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    if (pill.isDisabled) {
      children.add(
        const Text(
          'Disabilitata',
          style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500),
        ),
      );
    }

    if (children.length == 1) {
      return children.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = pill.isDisabled;

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: Icon(
            Icons.medication,
            color: disabled ? Colors.grey : Colors.blue,
          ),
          title: Text(
            pill.name,
            style: theme.textTheme.titleMedium?.copyWith(
              decoration: disabled ? TextDecoration.lineThrough : null,
              color: disabled ? Colors.grey : null,
            ),
          ),
          subtitle: _buildSubtitle(pill),
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
      ),
    );
  }
}
