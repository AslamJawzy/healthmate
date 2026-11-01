import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../models/health_record.dart';

/// REPOSITORY LAYER
/// The only class that talks to the health_records table.
/// ViewModels call these methods and never write SQL themselves.
/// This keeps database code in one place (separation of responsibilities).
class HealthRecordRepository {
  final DatabaseHelper _dbHelper;

  HealthRecordRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const String _table = DatabaseHelper.tableHealthRecords;

  // CREATE
  Future<int> insertRecord(HealthRecord record) async {
    final db = await _dbHelper.database;
    return db.insert(
      _table,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // READ: all records, newest first
  Future<List<HealthRecord>> getAllRecords() async {
    final db = await _dbHelper.database;
    final rows = await db.query(_table, orderBy: '${DatabaseHelper.colDate} DESC');
    return rows.map(HealthRecord.fromMap).toList();
  }

  // READ: one record for an exact date (used for search by date)
  Future<HealthRecord?> getRecordByDate(String date) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _table,
      where: '${DatabaseHelper.colDate} = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return HealthRecord.fromMap(rows.first);
  }

  // READ: records between two dates (used for week and month filters)
  Future<List<HealthRecord>> getRecordsBetween(String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _table,
      where: '${DatabaseHelper.colDate} BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: '${DatabaseHelper.colDate} DESC',
    );
    return rows.map(HealthRecord.fromMap).toList();
  }

  // UPDATE
  Future<int> updateRecord(HealthRecord record) async {
    final db = await _dbHelper.database;
    return db.update(
      _table,
      record.toMap(),
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [record.id],
    );
  }

  // DELETE
  Future<int> deleteRecord(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      _table,
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [id],
    );
  }
}
