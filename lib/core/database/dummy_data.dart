import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../utils/app_date_utils.dart';
import 'database_helper.dart';

/// Inserts realistic sample records for the previous 14 days.
/// Today is left empty on purpose, so the user can add today's
/// record during testing and the demo.
class DummyData {
  static Future<void> insertHealthRecords(Database db) async {
    final random = Random(42); // Fixed seed: same sample data every install
    final today = AppDateUtils.today();
    final batch = db.batch();

    for (int daysAgo = 1; daysAgo <= 14; daysAgo++) {
      final day = DateTime(today.year, today.month, today.day - daysAgo);
      batch.insert(DatabaseHelper.tableHealthRecords, {
        DatabaseHelper.colDate: AppDateUtils.toDbString(day),
        DatabaseHelper.colSteps: 4000 + random.nextInt(8000), // 4,000 to 12,000
        DatabaseHelper.colCalories: 200 + random.nextInt(450), // 200 to 650 kcal
        DatabaseHelper.colWater: 1200 + random.nextInt(8) * 200, // 1,200 to 2,600 ml
      });
    }

    await batch.commit(noResult: true);
  }
}
