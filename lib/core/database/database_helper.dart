import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'dummy_data.dart';
import 'sri_lankan_foods.dart';

/// DATA LAYER
/// DatabaseHelper opens the SQLite database file on the phone and
/// creates the tables the first time the app runs.
///
/// It is a "singleton": only ONE instance exists in the whole app,
/// so we never open the same database file twice.
///
/// Version history:
///   1 - health_records table
///   2 - foods, food_entries and sleep_records tables
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _databaseName = 'healthmate.db';
  static const int _databaseVersion = 2;

  // ---------- health_records (required by the coursework) ----------
  static const String tableHealthRecords = 'health_records';
  static const String colId = 'id';
  static const String colDate = 'date';
  static const String colSteps = 'steps';
  static const String colCalories = 'calories';
  static const String colWater = 'water';

  // ---------- extra tables ----------
  static const String tableFoods = 'foods'; // built-in food list
  static const String tableFoodEntries = 'food_entries'; // what the user ate
  static const String tableSleepRecords = 'sleep_records';

  // We keep the Future (not just the Database) so that if several
  // ViewModels ask for the database at the same moment on startup,
  // they all wait for the SAME opening instead of opening it twice.
  Future<Database>? _database;

  /// Returns the open database. Opens it the first time it is needed.
  Future<Database> get database => _database ??= _initDatabase();

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Runs only once, when the database file is created for the first time.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableHealthRecords (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colDate TEXT NOT NULL UNIQUE,
        $colSteps INTEGER NOT NULL,
        $colCalories INTEGER NOT NULL,
        $colWater INTEGER NOT NULL
      )
    ''');

    // Insert sample records so the app has data to show for testing.
    await DummyData.insertHealthRecords(db);

    await _createVersion2Tables(db);
  }

  /// Runs when an older version of the app is updated.
  /// Existing health records are kept; only the new tables are added.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createVersion2Tables(db);
    }
  }

  Future<void> _createVersion2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE $tableFoods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        portion TEXT NOT NULL,
        calories INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableFoodEntries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        meal TEXT NOT NULL,
        food_name TEXT NOT NULL,
        portion TEXT NOT NULL,
        servings REAL NOT NULL,
        calories INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableSleepRecords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        bed_time TEXT NOT NULL,
        wake_time TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        quality INTEGER NOT NULL
      )
    ''');

    // An index makes "entries for this date" queries fast.
    await db.execute('CREATE INDEX idx_food_entries_date ON $tableFoodEntries(date)');

    await SriLankanFoods.insertInto(db);
    await DummyData.insertSleepRecords(db);
  }
}
