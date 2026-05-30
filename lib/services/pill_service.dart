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

  /// History combinata: assunzioni + cambiamenti di dosaggio, ordinate per timestamp
  Future<List<HistoryEntry>> getCombinedHistory() async {
    final intakeMaps = await _db.getAllIntakesWithPillName();
    final changeMaps = await _db.getAllDosageChangesWithPillName();

    // Map per tracciare il dosaggio corrente di ogni pillola
    final currentDosage = <int, String>{};
    final entries = <HistoryEntry>[];

    // Unisco tutto e ordino per timestamp crescente
    final allItems = <_HistoryItem>[];
    for (final map in intakeMaps) {
      allItems.add(_HistoryItem(
        type: _HistoryItemType.intake,
        pillId: map['pill_id'] as int,
        pillName: map['pill_name'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['taken_at'] as int),
      ));
    }
    for (final map in changeMaps) {
      allItems.add(_HistoryItem(
        type: _HistoryItemType.dosageChange,
        pillId: map['pill_id'] as int,
        pillName: map['pill_name'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['changed_at'] as int),
        oldDosage: map['old_dosage'] as String,
        newDosage: map['new_dosage'] as String,
      ));
    }
    allItems.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Single pass: ricostruisco il dosaggio per ogni pillola
    for (final item in allItems) {
      if (item.type == _HistoryItemType.dosageChange) {
        currentDosage[item.pillId] = item.newDosage!;
        entries.add(DosageChangeEntry(
          pillName: item.pillName,
          oldDosage: item.oldDosage!,
          newDosage: item.newDosage!,
          timestamp: item.timestamp,
        ));
      } else {
        final dosage = currentDosage[item.pillId] ?? 'N/D';
        entries.add(IntakeEntry(
          pillName: item.pillName,
          dosage: dosage,
          timestamp: item.timestamp,
        ));
      }
    }

    // Inverso per il display (più recente prima)
    return entries.reversed.toList();
  }

  /// Controlla se una pillola è stata assunta oggi
  Future<bool> isTakenToday(int pillId) async {
    return _db.isTakenToday(pillId);
  }
}

/// Entry base per la history combinata
sealed class HistoryEntry {
  String get pillName;
  DateTime get timestamp;
}

/// Assunzione di una pillola con dosaggio ricostruito
class IntakeEntry implements HistoryEntry {
  @override
  final String pillName;
  final String dosage;
  @override
  final DateTime timestamp;

  IntakeEntry({
    required this.pillName,
    required this.dosage,
    required this.timestamp,
  });
}

/// Cambio di dosaggio di una pillola
class DosageChangeEntry implements HistoryEntry {
  @override
  final String pillName;
  final String oldDosage;
  final String newDosage;
  @override
  final DateTime timestamp;

  DosageChangeEntry({
    required this.pillName,
    required this.oldDosage,
    required this.newDosage,
    required this.timestamp,
  });
}

/// Item intermedio per il merge cronologico
enum _HistoryItemType { intake, dosageChange }

class _HistoryItem {
  final _HistoryItemType type;
  final int pillId;
  final String pillName;
  final DateTime timestamp;
  final String? oldDosage;
  final String? newDosage;

  _HistoryItem({
    required this.type,
    required this.pillId,
    required this.pillName,
    required this.timestamp,
    this.oldDosage,
    this.newDosage,
  });
}
