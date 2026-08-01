import '../data/app_database.dart';
import 'notification_service.dart';

/// Pill and intake management service
class PillService {
  final AppDatabase _db = AppDatabase();
  final NotificationService _notif = NotificationService();

  /// Add a new pill and schedule notification
  Future<Pill> addPill({
    required String name,
    required String time,
    required String quantity,
    int? totalDoses,
    bool isDisabled = false,
  }) async {
    final id = await _db.insertPill(
      name: name,
      time: time,
      quantity: quantity,
      totalDoses: totalDoses,
      isDisabled: isDisabled,
    );
    final pill = await _db.getPillById(id);
    if (pill != null && !pill.isDisabled) {
      await _notif.scheduleDailyNotification(
        id: id,
        name: pill.name,
        quantity: pill.quantity,
        time: pill.time,
      );
    }
    return pill!;
  }

  /// Update an existing pill
  Future<void> updatePill(Pill pill) async {
    final current = await _db.getPillById(pill.id!);
    await _db.updatePill(pill);

    if (pill.isDisabled) {
      // Disabled → cancel notification
      await _notif.cancelNotification(pill.id!);
    } else if (current == null || current.isDisabled) {
      // Just enabled → schedule notification
      await _notif.scheduleDailyNotification(
        id: pill.id!,
        name: pill.name,
        quantity: pill.quantity,
        time: pill.time,
      );
    } else {
      // Already enabled → cancel and reschedule (e.g. time changed)
      await _notif.cancelNotification(pill.id!);
      await _notif.scheduleDailyNotification(
        id: pill.id!,
        name: pill.name,
        quantity: pill.quantity,
        time: pill.time,
      );
    }
  }

  /// Delete a pill and its notification
  Future<void> deletePill(int id) async {
    await _notif.cancelNotification(id);
    await _db.deleteIntakesForPill(id);
    await _db.deletePill(id);
  }

  /// Get all pills ordered by time
  Future<List<Pill>> getAllPills() async {
    return _db.getAllPills();
  }

  /// Get overdue pills (past time, not taken today)
  Future<List<Pill>> getOverduePills() async {
    final allPills = await _db.getAllPills();
    final now = DateTime.now();
    final overdue = <Pill>[];

    for (final pill in allPills) {
      if (pill.isDisabled) continue;

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

  /// Log a pill intake
  Future<void> logIntake(int pillId) async {
    await _db.insertIntake(
      pillId: pillId,
      takenAt: DateTime.now(),
    );
  }

  /// Combined history: intakes + dosage changes, ordered by timestamp
  Future<List<HistoryEntry>> getCombinedHistory() async {
    final intakeMaps = await _db.getAllIntakesWithPillName();
    final changeMaps = await _db.getAllDosageChangesWithPillName();

    // Map to track current dosage per pill
    final currentDosage = <int, String>{};
    final entries = <HistoryEntry>[];

    // Merge all items and sort by ascending timestamp
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

    // Single pass: reconstruct dosage per pill
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

    // Reverse for display (most recent first)
    return entries.reversed.toList();
  }

  /// Check if a pill was taken today
  Future<bool> isTakenToday(int pillId) async {
    return _db.isTakenToday(pillId);
  }
}

/// Base entry for combined history
sealed class HistoryEntry {
  String get pillName;
  DateTime get timestamp;
}

/// Pill intake with reconstructed dosage
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

/// Pill dosage change
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

/// Intermediate item for chronological merge
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
