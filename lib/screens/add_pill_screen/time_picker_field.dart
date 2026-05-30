import 'package:flutter/material.dart';

/// Campo per selezionare l'ora di assunzione
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
      decoration: const InputDecoration(
        labelText: 'Ora assunzione',
        prefixIcon: Icon(Icons.access_time),
        border: OutlineInputBorder(),
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
