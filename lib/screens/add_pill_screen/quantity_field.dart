import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Input field for dosage
class QuantityField extends StatelessWidget {
  final TextEditingController controller;

  const QuantityField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: S.of(context)!.dosageLabel,
        hintText: S.of(context)!.dosageHint,
        prefixIcon: const Icon(Icons.scale),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return S.of(context)!.dosageValidator;
        }
        return null;
      },
    );
  }
}
