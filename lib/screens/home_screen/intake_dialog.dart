import 'package:flutter/material.dart';

/// Dialog per confermare l'assunzione di una pillola
class IntakeDialog extends StatelessWidget {
  final String pillName;
  final String quantity;

  const IntakeDialog({
    super.key,
    required this.pillName,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.medication, color: Colors.green),
      title: Text('Hai assunto $pillName?'),
      content: Text(quantity),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('No'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sì, assunta'),
        ),
      ],
    );
  }
}
