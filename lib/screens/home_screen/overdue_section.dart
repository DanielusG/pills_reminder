import 'package:flutter/material.dart';
import '../../data/app_database.dart';

/// Sezione delle pillole scadute da assumere
class OverdueSection extends StatelessWidget {
  final List<Pill> overduePills;
  final ValueChanged<int> onTaken;
  final bool isLoading;

  const OverdueSection({
    super.key,
    required this.overduePills,
    required this.onTaken,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (overduePills.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Da assumere',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...overduePills.map((pill) => _OverduePillCard(
          pill: pill,
          onTaken: () => onTaken(pill.id!),
        )),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _OverduePillCard extends StatelessWidget {
  final Pill pill;
  final VoidCallback onTaken;

  const _OverduePillCard({
    required this.pill,
    required this.onTaken,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.medication, color: Colors.orange),
        title: Text(pill.name),
        subtitle: Text('${pill.quantity} • ${pill.time}'),
        trailing: FilledButton.icon(
          onPressed: onTaken,
          icon: const Icon(Icons.check),
          label: const Text('Assunta'),
        ),
      ),
    );
  }
}
