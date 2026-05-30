import 'package:flutter/material.dart';

/// Campo di input per il nome del farmaco
class NameField extends StatelessWidget {
  final TextEditingController controller;

  const NameField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Nome farmaco',
        hintText: 'Es. Ibuprofene, Omeprazolo',
        prefixIcon: Icon(Icons.medication),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Inserisci il nome del farmaco';
        }
        return null;
      },
    );
  }
}
