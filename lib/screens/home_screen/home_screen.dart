import 'package:flutter/material.dart';
import '../../data/app_database.dart';
import '../../services/notification_service.dart';
import '../../services/pill_service.dart';
import '../add_pill_screen/add_pill_screen.dart';
import '../history_screen/history_screen.dart';
import 'intake_dialog.dart';
import 'overdue_section.dart';
import 'pills_list_section.dart';

/// Schermata principale dell'app
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = PillService();
  List<Pill> _pills = [];
  List<Pill> _overduePills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    NotificationService().addListener(_onNotificationTap);
  }

  @override
  void dispose() {
    NotificationService().removeListener(_onNotificationTap);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final pills = await _service.getAllPills();
    final overdue = await _service.getOverduePills();
    setState(() {
      _pills = pills;
      _overduePills = overdue;
      _isLoading = false;
    });
  }

  void _onNotificationTap() {
    _loadData();
  }

  Future<void> _addPill() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddPillScreen()),
    );
    await _loadData();
  }

  Future<void> _editPill(Pill pill) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddPillScreen(pill: pill)),
    );
    await _loadData();
  }

  Future<void> _deletePill(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.delete, color: Colors.red),
        title: const Text('Elimina pillola?'),
        content: const Text('Questa azione eliminerà anche lo storico delle assunzioni.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deletePill(id);
      await _loadData();
    }
  }

  Future<void> _markAsTaken(int pillId) async {
    final pill = _overduePills.firstWhere((p) => p.id == pillId);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => IntakeDialog(
        pillName: pill.name,
        quantity: pill.quantity,
      ),
    );

    if (confirmed == true) {
      await _service.logIntake(pillId);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pill Reminder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
            tooltip: 'Storico assunzioni',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                children: [
                  OverdueSection(
                    overduePills: _overduePills,
                    onTaken: _markAsTaken,
                    isLoading: _isLoading,
                  ),
                  PillsListSection(
                    pills: _pills,
                    onEdit: _editPill,
                    onDelete: _deletePill,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPill,
        icon: const Icon(Icons.add),
        label: const Text('Nuova pillola'),
      ),
    );
  }
}
