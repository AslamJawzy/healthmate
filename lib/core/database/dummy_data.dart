import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../utils/app_date_utils.dart';
import 'database_helper.dart';

/// Inserts realistic sample data for the previous 14 days.
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

  /// Sample sleep for the last 7 nights (bed 22:00 to 00:30, wake 05:30 to 07:30).
  static Future<void> insertSleepRecords(Database db) async {
    final random = Random(7);
    final today = AppDateUtils.today();
    final batch = db.batch();

    for (int daysAgo = 1; daysAgo <= 7; daysAgo++) {
      final day = DateTime(today.year, today.month, today.day - daysAgo);
      final bedMinutes = 22 * 60 + random.nextInt(6) * 30; // 22:00 to 00:30
      final wakeMinutes = 5 * 60 + 30 + random.nextInt(5) * 30; // 05:30 to 07:30
      final duration = (24 * 60 - bedMinutes) + wakeMinutes;
      batch.insert(DatabaseHelper.tableSleepRecords, {
        'date': AppDateUtils.toDbString(day),
        'bed_time': _hhmm(bedMinutes % (24 * 60)),
        'wake_time': _hhmm(wakeMinutes),
        'duration_minutes': duration,
        'quality': 3 + random.nextInt(3), // 3 to 5
      });
    }
    await batch.commit(noResult: true);
  }

  static String _hhmm(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
