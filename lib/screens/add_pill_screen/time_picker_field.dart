import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Time picker for intake time
class TimePickerField extends StatelessWidget {
  final TimeOfDay selectedTime;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const TimePickerField({
    super.key,
    required this.selectedTime,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(
        text: '${selectedTime.hour.toString().padLeft(2, '0')}:'
            '${selectedTime.minute.toString().padLeft(2, '0')}',
      ),
      decoration: InputDecoration(
        labelText: S.of(context)!.intakeTimeLabel,
        prefixIcon: const Icon(Icons.access_time),
        border: const OutlineInputBorder(),
      ),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: selectedTime,
        );
        if (picked != null) {
          onTimeChanged(picked);
        }
      },
    );
  }
}
