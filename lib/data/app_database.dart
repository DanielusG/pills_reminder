import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Modello pillola
class Pill {
  final int? id;
  final String name;
  final String time; // formato "HH:MM"
  final String quantity;
  final DateTime createdAt;

  Pill({
    this.id,
    required this.name,
    required this.time,
    required this.quantity,
    required this.createdAt,
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
    return map;
  }

  factory Pill.fromMap(Map<String, Object?> map) {
    return Pill(
      id: map['id'] as int?,
      name: map['name'] as String,
      time: map['time'] as String,
      quantity: map['quantity'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Pill copyWith({String? name, String? time, String? quantity}) {
    return Pill(
      id: id,
      name: name ?? this.name,
      time: time ?? this.time,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt,
    );
  }
}

/// Modello assunzione
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

/// Database helper per le pillole
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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pills (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            time TEXT NOT NULL,
            quantity TEXT NOT NULL,
            created_at INTEGER NOT NULL
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
      },
    );
  }

  // ── Pills CRUD ──

  Future<int> insertPill({
    required String name,
    required String time,
    required String quantity,
  }) async {
    final db = await database;
    return db.insert('pills', Pill(
      name: name,
      time: time,
      quantity: quantity,
      createdAt: DateTime.now(),
    ).toMap());
  }

  Future<int> updatePill(Pill pill) async {
    final db = await database;
    return db.update('pills', pill.toMap(), where: 'id = ?', whereArgs: [pill.id]);
  }

  Future<int> deletePill(int id) async {
    final db = await database;
    return db.delete('pills', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Pill>> getAllPills() async {
    final db = await database;
    final maps = await db.query('pills', orderBy: 'time ASC');
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

  /// Controlla se una pillola è già stata assunta oggi
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

  /// Elimina tutti gli intake associati a una pillola
  Future<int> deleteIntakesForPill(int pillId) async {
    final db = await database;
    return db.delete('pill_intakes', where: 'pill_id = ?', whereArgs: [pillId]);
  }

  /// Chiude il database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
