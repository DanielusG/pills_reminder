import '../data/app_database.dart';
import 'notification_service.dart';

/// Servizio per la gestione delle pillole e delle assunzioni
class PillService {
  final AppDatabase _db = AppDatabase();
  final NotificationService _notif = NotificationService();

  /// Aggiunge una nuova pillola e schedula la notifica
  Future<Pill> addPill({
    required String name,
    required String time,
    required String quantity,
  }) async {
    final id = await _db.insertPill(
      name: name,
      time: time,
      quantity: quantity,
    );
    final pill = await _db.getPillById(id);
    if (pill != null) {
      await _notif.scheduleDailyNotification(
        id: id,
        name: pill.name,
        quantity: pill.quantity,
        time: pill.time,
      );
    }
    return pill!;
  }

  /// Aggiorna una pillola esistente
  Future<void> updatePill(Pill pill) async {
    await _db.updatePill(pill);
    await _notif.cancelNotification(pill.id!);
    await _notif.scheduleDailyNotification(
      id: pill.id!,
      name: pill.name,
      quantity: pill.quantity,
      time: pill.time,
    );
  }

  /// Elimina una pillola e la sua notifica
  Future<void> deletePill(int id) async {
    await _notif.cancelNotification(id);
    await _db.deleteIntakesForPill(id);
    await _db.deletePill(id);
  }

  /// Ottiene tutte le pillole ordinate per orario
  Future<List<Pill>> getAllPills() async {
    return _db.getAllPills();
  }

  /// Ottiene le pillole scadute (orario passato, non assunte oggi)
  Future<List<Pill>> getOverduePills() async {
    final allPills = await _db.getAllPills();
    final now = DateTime.now();
    final overdue = <Pill>[];

    for (final pill in allPills) {
      final isTaken = await _db.isTakenToday(pill.id!);
      if (isTaken) continue;

      final parts = pill.time.split(':');
      final pillHour = int.parse(parts[0]);
      final pillMinute = int.parse(parts[1]);
      final pillTimeToday = DateTime(
        now.year,
        now.month,
        now.day,
        pillHour,
        pillMinute,
      );

      if (pillTimeToday.isBefore(now)) {
        overdue.add(pill);
      }
    }

    return overdue;
  }

  /// Registra l'assunzione di una pillola
  Future<void> logIntake(int pillId) async {
    await _db.insertIntake(
      pillId: pillId,
      takenAt: DateTime.now(),
    );
  }

  /// Ottiene lo storico delle assunzioni con nome farmaco
  Future<List<IntakeRecord>> getIntakeHistory() async {
    final intakes = await _db.getAllIntakes();
    final records = <IntakeRecord>[];

    for (final intake in intakes) {
      final pill = await _db.getPillById(intake.pillId);
      if (pill != null) {
        records.add(IntakeRecord(
          pill: pill,
          takenAt: intake.takenAt,
        ));
      }
    }

    return records;
  }

  /// Controlla se una pillola è stata assunta oggi
  Future<bool> isTakenToday(int pillId) async {
    return _db.isTakenToday(pillId);
  }
}

/// Record che associa una pillola al momento dell'assunzione
class IntakeRecord {
  final Pill pill;
  final DateTime takenAt;

  IntakeRecord({required this.pill, required this.takenAt});
}
