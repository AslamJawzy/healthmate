import '../../../core/database/database_helper.dart';
import '../models/food_entry.dart';
import '../models/food_item.dart';

/// REPOSITORY: all SQL for the food list and the food diary.
class FoodRepository {
  final DatabaseHelper _dbHelper;

  FoodRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Searches the built-in food list. Empty query returns everything.
  Future<List<FoodItem>> searchFoods(String query) async {
    final db = await _dbHelper.database;
    final q = query.trim();
    final rows = await db.query(
      DatabaseHelper.tableFoods,
      where: q.isEmpty ? null : 'name LIKE ? OR category LIKE ?',
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%'],
      orderBy: 'category, name',
    );
    return rows.map(FoodItem.fromMap).toList();
  }

  Future<List<FoodEntry>> getEntriesForDate(String date) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableFoodEntries,
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'id',
    );
    return rows.map(FoodEntry.fromMap).toList();
  }

  /// Total kcal eaten per day between two dates, e.g. {"2026-08-18": 1850}.
  Future<Map<String, int>> dailyTotalsBetween(String start, String end) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT date, SUM(calories) AS total FROM ${DatabaseHelper.tableFoodEntries} '
      'WHERE date BETWEEN ? AND ? GROUP BY date',
      [start, end],
    );
    return {for (final r in rows) r['date'] as String: (r['total'] as num).toInt()};
  }

  Future<int> insertEntry(FoodEntry entry) async {
    final db = await _dbHelper.database;
    return db.insert(DatabaseHelper.tableFoodEntries, entry.toMap());
  }

  Future<int> deleteEntry(int id) async {
    final db = await _dbHelper.database;
    return db.delete(DatabaseHelper.tableFoodEntries, where: 'id = ?', whereArgs: [id]);
  }
}
