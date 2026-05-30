import 'package:flutter/material.dart';
import '../../data/app_database.dart';
import '../../services/pill_service.dart';
import 'name_field.dart';
import 'quantity_field.dart';
import 'time_picker_field.dart';

/// Schermata per aggiungere/modificare una pillola
class AddPillScreen extends StatefulWidget {
  final Pill? pill; // null = nuova pillola, non-null = modifica

  const AddPillScreen({super.key, this.pill});

  @override
  State<AddPillScreen> createState() => _AddPillScreenState();
}

class _AddPillScreenState extends State<AddPillScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late TimeOfDay _selectedTime;

  final _service = PillService();

  @override
  void initState() {
    super.initState();
    final pill = widget.pill;
    _nameController = TextEditingController(text: pill?.name ?? '');
    _quantityController = TextEditingController(text: pill?.quantity ?? '');

    if (pill != null) {
      final parts = pill.time.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else {
      _selectedTime = const TimeOfDay(hour: 8, minute: 0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final time = _formatTime(_selectedTime);

    try {
      if (widget.pill == null) {
        await _service.addPill(
          name: _nameController.text.trim(),
          time: time,
          quantity: _quantityController.text.trim(),
        );
      } else {
        final updated = widget.pill!.copyWith(
          name: _nameController.text.trim(),
          time: time,
          quantity: _quantityController.text.trim(),
        );
        await _service.updatePill(updated);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.pill != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifica pillola' : 'Nuova pillola'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NameField(controller: _nameController),
              const SizedBox(height: 16),
              TimePickerField(
                selectedTime: _selectedTime,
                onTimeChanged: (time) => setState(() => _selectedTime = time),
              ),
              const SizedBox(height: 16),
              QuantityField(controller: _quantityController),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _save,
                child: Text(isEditing ? 'Salva modifiche' : 'Aggiungi pillola'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
