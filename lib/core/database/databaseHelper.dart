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

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // -----------------------
    // ACTIVITIES (static)
    // -----------------------
    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        iconPath TEXT NOT NULL,
        route TEXT NOT NULL,
        time TEXT,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // -----------------------
    // ACTIVITY LOGS (daily state)
    // -----------------------
    await db.execute('''
      CREATE TABLE activity_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (activity_id) REFERENCES activities (id)
      )
    ''');

    // -----------------------
    // PROGRESS (journey state)
    // -----------------------
    await db.execute('''
      CREATE TABLE progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        current_level INTEGER NOT NULL DEFAULT 0,
        last_completed_date TEXT
      )
    ''');

    // -----------------------
    // USER PROFILE
    // -----------------------
    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT,
        age INTEGER,
        selected_journey TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }
}