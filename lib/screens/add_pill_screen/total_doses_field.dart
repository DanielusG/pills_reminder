import 'package:flutter/material.dart';

/// Campo di input opzionale per le dosi totali (target)
class TotalDosesField extends StatelessWidget {
  final TextEditingController controller;

  const TotalDosesField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Dosi totali (opzionale)',
        hintText: 'Es. 30',
        prefixIcon: const Icon(Icons.pin),
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          final parsed = int.tryParse(value.trim());
          if (parsed == null || parsed <= 0) {
            return 'Inserisci un numero valido maggiore di 0';
          }
        }
        return null;
      },
    );
  }
}
