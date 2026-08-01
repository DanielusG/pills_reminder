import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Pill model
class Pill {
  final int? id;
  final String name;
  final String time; // "HH:MM" format
  final String quantity;
  final DateTime createdAt;
  final int? totalDoses;         // target total doses (null = no target)
  final bool isDisabled;         // disabled pill (no notifications)
  final int? totalIntakeCount;   // total intake count (null = not loaded)

  Pill({
    this.id,
    required this.name,
    required this.time,
    required this.quantity,
    required this.createdAt,
    this.totalDoses,
    this.isDisabled = false,
    this.totalIntakeCount,
  });

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'name': name,
      'time': time,
      'quantity': quantity,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
    if (id != null) {
      map['id'] = id;
    }
    if (totalDoses != null) {
      map['total_doses'] = totalDoses;
    }
    map['is_disabled'] = isDisabled ? 1 : 0;
    return map;
  }

  factory Pill.fromMap(Map<String, Object?> map) {
    return Pill(
      id: map['id'] as int?,
      name: map['name'] as String,
      time: map['time'] as String,
      quantity: map['quantity'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      totalDoses: map['total_doses'] as int?,
      isDisabled: (map['is_disabled'] as int?) == 1,
      totalIntakeCount: map['total_intake_count'] as int?,
    );
  }

  Pill copyWith({
    String? name,
    String? time,
    String? quantity,
    int? totalDoses,
    bool? isDisabled,
  }) {
    return Pill(
      id: id,
      name: name ?? this.name,
      time: time ?? this.time,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt,
      totalDoses: totalDoses ?? this.totalDoses,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }
}

/// Dosage change model
class DosageChange {
  final int? id;
  final int pillId;
  final String oldDosage;
  final String newDosage;
  final DateTime changedAt;

  DosageChange({
    this.id,
    required this.pillId,
    required this.oldDosage,
    required this.newDosage,
    required this.changedAt,
  });

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'pill_id': pillId,
      'old_dosage': oldDosage,
      'new_dosage': newDosage,
      'changed_at': changedAt.millisecondsSinceEpoch,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory DosageChange.fromMap(Map<String, Object?> map) {
    return DosageChange(
      id: map['id'] as int?,
      pillId: map['pill_id'] as int,
      oldDosage: map['old_dosage'] as String,
      newDosage: map['new_dosage'] as String,
      changedAt: DateTime.fromMillisecondsSinceEpoch(map['changed_at'] as int),
    );
  }
}

/// Pill intake model
class PillIntake {
  final int? id;
  final int pillId;
  final DateTime takenAt;

  PillIntake({
    this.id,
    required this.pillId,
    required this.takenAt,
  });

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'pill_id': pillId,
      'taken_at': takenAt.millisecondsSinceEpoch,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory PillIntake.fromMap(Map<String, Object?> map) {
    return PillIntake(
      id: map['id'] as int?,
      pillId: map['pill_id'] as int,
      takenAt: DateTime.fromMillisecondsSinceEpoch(map['taken_at'] as int),
    );
  }
}

/// Database helper
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _database;

  factory AppDatabase() => _instance;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pills_reminder.db');

    return openDatabase(
      path,
      version: 4,
      onCreate: _createTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE pill_dosage_changes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              pill_id INTEGER NOT NULL,
              old_dosage TEXT NOT NULL,
              new_dosage TEXT NOT NULL,
              changed_at INTEGER NOT NULL,
              FOREIGN KEY (pill_id) REFERENCES pills(id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE pills ADD COLUMN total_doses INTEGER');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE pills ADD COLUMN is_disabled INTEGER DEFAULT 0');
        }
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        time TEXT NOT NULL,
        quantity TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        total_doses INTEGER,
        is_disabled INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE pill_intakes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pill_id INTEGER NOT NULL,
        taken_at INTEGER NOT NULL,
        FOREIGN KEY (pill_id) REFERENCES pills(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE pill_dosage_changes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pill_id INTEGER NOT NULL,
        old_dosage TEXT NOT NULL,
        new_dosage TEXT NOT NULL,
        changed_at INTEGER NOT NULL,
        FOREIGN KEY (pill_id) REFERENCES pills(id) ON DELETE CASCADE
      )
    ''');
  }

  // ── Pills CRUD ──

  Future<int> insertPill({
    required String name,
    required String time,
    required String quantity,
    int? totalDoses,
    bool isDisabled = false,
  }) async {
    final db = await database;
    final now = DateTime.now();
    final pillId = await db.insert('pills', Pill(
      name: name,
      time: time,
      quantity: quantity,
      createdAt: now,
      totalDoses: totalDoses,
      isDisabled: isDisabled,
    ).toMap());

    // Initial dosage log entry
    await db.insert('pill_dosage_changes', DosageChange(
      pillId: pillId,
      oldDosage: '',
      newDosage: quantity,
      changedAt: now,
    ).toMap());

    return pillId;
  }

  Future<int> updatePill(Pill pill) async {
    final db = await database;
    final current = await getPillById(pill.id!);
    if (current == null) return 0;

    // Log dosage change
    if (current.quantity != pill.quantity) {
      await db.insert('pill_dosage_changes', DosageChange(
        pillId: pill.id!,
        oldDosage: current.quantity,
        newDosage: pill.quantity,
        changedAt: DateTime.now(),
      ).toMap());
    }

    return db.update('pills', pill.toMap(), where: 'id = ?', whereArgs: [pill.id]);
  }

  Future<int> deletePill(int id) async {
    final db = await database;
    return db.delete('pills', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Pill>> getAllPills() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT p.*, COUNT(pi.id) AS total_intake_count
      FROM pills p
      LEFT JOIN pill_intakes pi ON p.id = pi.pill_id
      GROUP BY p.id
      ORDER BY p.time ASC
    ''');
    return maps.map((map) => Pill.fromMap(map)).toList();
  }

  Future<Pill?> getPillById(int id) async {
    final db = await database;
    final maps = await db.query('pills', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Pill.fromMap(maps.first);
  }

  // ── Pill Intakes ──

  Future<int> insertIntake({required int pillId, required DateTime takenAt}) async {
    final db = await database;
    return db.insert('pill_intakes', PillIntake(pillId: pillId, takenAt: takenAt).toMap());
  }

  Future<List<PillIntake>> getAllIntakes() async {
    final db = await database;
    final maps = await db.query('pill_intakes', orderBy: 'taken_at DESC');
    return maps.map((map) => PillIntake.fromMap(map)).toList();
  }

  Future<List<PillIntake>> getIntakesForPill(int pillId) async {
    final db = await database;
    final maps = await db.query(
      'pill_intakes',
      where: 'pill_id = ?',
      whereArgs: [pillId],
      orderBy: 'taken_at DESC',
    );
    return maps.map((map) => PillIntake.fromMap(map)).toList();
  }

  /// Check if a pill has been taken today
  Future<bool> isTakenToday(int pillId) async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.rawQuery(
      'SELECT EXISTS(SELECT 1 FROM pill_intakes WHERE pill_id = ? AND taken_at >= ? AND taken_at < ?)',
      [pillId, startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
    );

    return (result.first.values.first as int) == 1;
  }

  /// Delete all intakes for a pill
  Future<int> deleteIntakesForPill(int pillId) async {
    final db = await database;
    return db.delete('pill_intakes', where: 'pill_id = ?', whereArgs: [pillId]);
  }

  // ── Combined history queries ──

  /// Intakes with pill name (JOIN), ordered by taken_at ASC
  Future<List<Map<String, Object?>>> getAllIntakesWithPillName() async {
    final db = await database;
    return db.rawQuery('''
      SELECT i.id, i.pill_id, i.taken_at, p.name AS pill_name
      FROM pill_intakes i
      LEFT JOIN pills p ON i.pill_id = p.id
      WHERE p.id IS NOT NULL
      ORDER BY i.taken_at ASC
    ''');
  }

  /// Dosage changes with pill name (JOIN), ordered by changed_at ASC
  Future<List<Map<String, Object?>>> getAllDosageChangesWithPillName() async {
    final db = await database;
    return db.rawQuery('''
      SELECT c.id, c.pill_id, c.old_dosage, c.new_dosage, c.changed_at, p.name AS pill_name
      FROM pill_dosage_changes c
      LEFT JOIN pills p ON c.pill_id = p.id
      WHERE p.id IS NOT NULL
      ORDER BY c.changed_at ASC
    ''');
  }

  // ── Raw methods for Import/Export ──

  /// Return all pills as raw maps (for JSON export)
  Future<List<Map<String, dynamic>>> getAllPillsRaw() async {
    final db = await database;
    return db.query('pills');
  }

  /// Return all intakes as raw maps
  Future<List<Map<String, dynamic>>> getAllIntakesRaw() async {
    final db = await database;
    return db.query('pill_intakes');
  }

  /// Return all dosage changes as raw maps
  Future<List<Map<String, dynamic>>> getAllDosageChangesRaw() async {
    final db = await database;
    return db.query('pill_dosage_changes');
  }

  /// Truncate all tables (for import)
  Future<void> truncateAllTables() async {
    final db = await database;
    await db.delete('pill_intakes');
    await db.delete('pill_dosage_changes');
    await db.delete('pills');
  }

  /// Insert a pill preserving the original ID
  Future<void> insertPillRaw(Map<String, dynamic> map) async {
    final db = await database;
    await db.insert('pills', map);
  }

  /// Insert an intake preserving the original ID
  Future<void> insertIntakeRaw(Map<String, dynamic> map) async {
    final db = await database;
    await db.insert('pill_intakes', map);
  }

  /// Insert a dosage change preserving the original ID
  Future<void> insertDosageChangeRaw(Map<String, dynamic> map) async {
    final db = await database;
    await db.insert('pill_dosage_changes', map);
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
