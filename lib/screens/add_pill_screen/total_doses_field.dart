import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Optional total doses (target) input field
class TotalDosesField extends StatelessWidget {
  final TextEditingController controller;

  const TotalDosesField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: S.of(context)!.totalDosesLabel,
        hintText: S.of(context)!.totalDosesHint,
        prefixIcon: const Icon(Icons.pin),
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          final parsed = int.tryParse(value.trim());
          if (parsed == null || parsed <= 0) {
            return S.of(context)!.totalDosesValidator;
          }
        }
        return null;
      },
    );
  }
}
