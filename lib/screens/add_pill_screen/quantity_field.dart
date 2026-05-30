import 'package:flutter/material.dart';

/// Campo di input per il dosaggio
class QuantityField extends StatelessWidget {
  final TextEditingController controller;

  const QuantityField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Quantità / Dosaggio',
        hintText: 'Es. 1 compressa, 5ml, 2 capsule',
        prefixIcon: Icon(Icons.scale),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Inserisci il dosaggio';
        }
        return null;
      },
    );
  }
}
