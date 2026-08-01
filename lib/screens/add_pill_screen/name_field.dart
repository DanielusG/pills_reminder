import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Input field for medication name
class NameField extends StatelessWidget {
  final TextEditingController controller;

  const NameField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: S.of(context)!.medicationNameLabel,
        hintText: S.of(context)!.medicationNameHint,
        prefixIcon: const Icon(Icons.medication),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return S.of(context)!.medicationNameValidator;
        }
        return null;
      },
    );
  }
}
