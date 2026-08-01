import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_database.dart';
import 'notification_service.dart';

/// Import/export service for app data (pills, intakes, dosage changes)
class ImportExportService {
  final AppDatabase _db = AppDatabase();
  final NotificationService _notif = NotificationService();

  /// Backup format version
  static const int _backupVersion = 1;

  /// Export all data to a JSON file and share it
  Future<void> exportData() async {
    final pills = await _db.getAllPillsRaw();
    final intakes = await _db.getAllIntakesRaw();
    final dosageChanges = await _db.getAllDosageChangesRaw();

    final backup = {
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'pills': pills,
      'intakes': intakes,
      'dosageChanges': dosageChanges,
    };

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = _formatTimestamp(DateTime.now());
    final fileName = 'pills_backup_$timestamp.json';
    final file = File('${dir.path}/$fileName');

    await file.writeAsString(jsonEncode(backup));

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Backup Pill Reminder',
      ),
    );

    return;
  }

  /// Import data from a JSON file (in-memory bytes)
  /// Replaces all existing data
  Future<void> importData(Uint8List bytes) async {
    final jsonString = utf8.decode(bytes);
    final Map<String, dynamic> backup = jsonDecode(jsonString);

    // Validate
    if (!backup.containsKey('pills') ||
        !backup.containsKey('intakes') ||
        !backup.containsKey('dosageChanges')) {
      throw const FormatException('Invalid backup file: missing fields.');
    }

    final int version = backup['version'] ?? 0;
    if (version != _backupVersion) {
      throw FormatException(
        'Unsupported backup version: $version (expected: $_backupVersion).',
      );
    }

    // Cancel all existing notifications
    await _notif.cancelAll();

    // Truncate tables
    await _db.truncateAllTables();

    // Re-insert pills
    final pills = List<Map<String, dynamic>>.from(backup['pills']);
    for (final pillMap in pills) {
      await _db.insertPillRaw(pillMap);
    }

    // Re-insert intakes
    final intakes = List<Map<String, dynamic>>.from(backup['intakes']);
    for (final intakeMap in intakes) {
      await _db.insertIntakeRaw(intakeMap);
    }

    // Re-insert dosage changes
    final dosageChanges = List<Map<String, dynamic>>.from(backup['dosageChanges']);
    for (final dcMap in dosageChanges) {
      await _db.insertDosageChangeRaw(dcMap);
    }

    // Reschedule notifications for each pill
    for (final pillMap in pills) {
      final pill = Pill.fromMap(pillMap);
      await _notif.scheduleDailyNotification(
        id: pill.id!,
        name: pill.name,
        quantity: pill.quantity,
        time: pill.time,
      );
    }
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)}_'
        '${_pad(dt.hour)}-${_pad(dt.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
