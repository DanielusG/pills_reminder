import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
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
        title: Text(S.of(context)!.historyTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Text(
                    S.of(context)!.noHistoryYet,
                    style: const TextStyle(color: Colors.grey),
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
