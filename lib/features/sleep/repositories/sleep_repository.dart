import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../models/sleep_record.dart';

/// REPOSITORY: all SQL for the sleep_records table.
class SleepRepository {
  final DatabaseHelper _dbHelper;

  SleepRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const _table = DatabaseHelper.tableSleepRecords;

  Future<List<SleepRecord>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query(_table, orderBy: 'date DESC');
    return rows.map(SleepRecord.fromMap).toList();
  }

  /// Insert, or replace the night if that date already has a record.
  Future<void> save(SleepRecord record) async {
    final db = await _dbHelper.database;
    if (record.id != null) {
      await db.update(_table, record.toMap(), where: 'id = ?', whereArgs: [record.id]);
    } else {
      await db.insert(_table, record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> delete(int id) async {
    final db = await _dbHelper.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
