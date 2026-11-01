import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'dummy_data.dart';

/// DATA LAYER
/// DatabaseHelper opens the SQLite database file on the phone and
/// creates the tables the first time the app runs.
///
/// It is a "singleton": only ONE instance exists in the whole app,
/// so we never open the same database file twice.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _databaseName = 'healthmate.db';
  static const int _databaseVersion = 1;

  // Table and column names in one place to avoid typing mistakes.
  static const String tableHealthRecords = 'health_records';
  static const String colId = 'id';
  static const String colDate = 'date';
  static const String colSteps = 'steps';
  static const String colCalories = 'calories';
  static const String colWater = 'water';

  Database? _database;

  /// Returns the open database. Opens it the first time it is needed.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
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
  }
}
