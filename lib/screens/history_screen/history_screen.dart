import 'package:flutter/material.dart';
import '../../services/pill_service.dart';
import 'dosage_change_card.dart';
import 'intake_card.dart';

/// Schermata storico delle assunzioni
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _service = PillService();
  List<HistoryEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final entries = await _service.getCombinedHistory();
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  Widget _buildEntry(HistoryEntry entry) {
    switch (entry) {
      case IntakeEntry():
        return IntakeCard(entry: entry);
      case DosageChangeEntry():
        return DosageChangeCard(entry: entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storico assunzioni'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(
                  child: Text(
                    'Nessuna assunzione registrata.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView(
                    children: [
                      ..._entries.map(_buildEntry),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }
}
