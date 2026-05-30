import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/import_export_service.dart';
import 'about_section.dart';

/// Schermata impostazioni con import/export
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = ImportExportService();
  bool _isProcessing = false;

  Future<void> _handleExport() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await _service.exportData();
      if (mounted) {
        _showSnackBar('Dati esportati con successo.');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Errore durante l\'esportazione: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleImport() async {
    if (_isProcessing) return;

    // Apri file picker per selezionare il file JSON
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    if (!mounted) return;

    // Chiedi conferma prima di sovrascrivere
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.orange),
        title: const Text('Sostituire i dati?'),
        content: const Text(
          'L\'importazione cancellerà tutti i dati attuali e li sostituirà con quelli dal backup. '
          'Questa azione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Importa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final fileBytes = result.files.first.bytes!;
      await _service.importData(fileBytes);

      if (mounted) {
        _showSnackBar('Dati importati con successo.');
        // Torna alla home per vedere i dati aggiornati
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Errore durante l\'importazione: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Esporta dati'),
                  subtitle: const Text(
                    'Salva farmaci e storico in un file JSON',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _handleExport,
                ),
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('Importa dati'),
                  subtitle: const Text(
                    'Ripristina da un file di backup',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _handleImport,
                ),
                const Divider(height: 32),
                const AboutSection(),
              ],
            ),
    );
  }
}
