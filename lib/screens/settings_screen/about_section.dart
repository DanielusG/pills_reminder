import 'package:flutter/material.dart';

/// Sezione "Informazioni" nella schermata impostazioni
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.medical_services, size: 48, color: Colors.blue),
          const SizedBox(height: 8),
          Text(
            'Pill Reminder',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Versione 1.0.0',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Tieni traccia delle tue assunzioni farmacologiche con promemoria giornalieri.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
