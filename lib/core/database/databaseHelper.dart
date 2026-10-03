import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // ACTIVITIES
    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        iconPath TEXT NOT NULL,
        route TEXT NOT NULL,
        duration TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        completed_on TEXT
      )
    ''');

    // ACTIVITY LOGS
    await db.execute('''
      CREATE TABLE activity_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        value TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT,
        FOREIGN KEY (activity_id) REFERENCES activities (id),
        UNIQUE(activity_id, date)
      )
    ''');

    // PROGRESS
    await db.execute('''
      CREATE TABLE progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        current_level INTEGER NOT NULL DEFAULT 0,
        last_completed_date TEXT,
        journey TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT
      )
    ''');

    // PROFILE (v2 layout, must match what _onUpgrade produces)
    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT,
        age INTEGER,
        selected_journey TEXT,
        created_at TEXT NOT NULL,
        date_of_birth TEXT,
        remote_id TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE profile ADD COLUMN date_of_birth TEXT');
      await db.execute('ALTER TABLE profile ADD COLUMN remote_id TEXT');
      await db.execute(
          'ALTER TABLE profile ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE profile ADD COLUMN updated_at TEXT');
      await db.execute('ALTER TABLE progress ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE progress ADD COLUMN updated_at TEXT');
      await db.execute('ALTER TABLE activity_logs ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE activity_logs ADD COLUMN updated_at TEXT');
      await db.execute('ALTER TABLE activities ADD COLUMN completed_on TEXT');
    }

    // Future versions go here, never edit the blocks above:
    // if (oldVersion < 3) { ... }
  }
}