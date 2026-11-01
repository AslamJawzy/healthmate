import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/utils/activity_calculator.dart';
import 'package:healthmate/core/utils/app_date_utils.dart';
import 'package:healthmate/core/utils/period.dart';
import 'package:healthmate/core/utils/validators.dart';
import 'package:healthmate/features/activity/models/step_counter_state.dart';
import 'package:healthmate/features/health_records/models/health_record.dart';
import 'package:healthmate/features/settings/models/user_settings.dart';

/// Unit tests. Run them with:  flutter test
void main() {
  group('Validators', () {
    test('empty steps shows an error', () {
      expect(Validators.steps(''), 'Please enter Steps');
    });

    test('text instead of a number shows an error', () {
      expect(Validators.water('abc'), 'Water intake must be a whole number');
    });

    test('value above the maximum shows an error', () {
      expect(Validators.calories('20000'), isNotNull);
    });

    test('valid value passes', () {
      expect(Validators.steps('7850'), isNull);
    });

    test('future date is rejected', () {
      final today = DateTime(2026, 8, 18);
      expect(Validators.notFutureDate(DateTime(2026, 8, 19), today), isNotNull);
      expect(Validators.notFutureDate(today, today), isNull);
    });
  });

  group('HealthRecord model', () {
    test('toMap and fromMap give back the same record', () {
      const record = HealthRecord(id: 1, date: '2026-08-18', steps: 7850, calories: 420, water: 2000);
      final copy = HealthRecord.fromMap(record.toMap());
      expect(copy.id, 1);
      expect(copy.date, '2026-08-18');
      expect(copy.steps, 7850);
      expect(copy.calories, 420);
      expect(copy.water, 2000);
    });
  });

  group('Date ranges', () {
    test('week runs Monday to Sunday', () {
      // 18 Aug 2026 is a Tuesday
      final range = AppDateUtils.rangeFor(Period.week, DateTime(2026, 8, 18));
      expect(range.start, DateTime(2026, 8, 17));
      expect(range.end, DateTime(2026, 8, 23));
    });

    test('month covers the whole month', () {
      final range = AppDateUtils.rangeFor(Period.month, DateTime(2026, 2, 10));
      expect(range.start, DateTime(2026, 2, 1));
      expect(range.end, DateTime(2026, 2, 28));
    });
  });

  group('Automatic step counter', () {
    test('first reading starts at 0 steps', () {
      final s = StepCounterState.update(null, 5000, '2026-08-18');
      expect(s.todaySteps, 0);
    });

    test('steps increase during the day', () {
      final a = StepCounterState.update(null, 1000, '2026-08-18');
      final b = StepCounterState.update(a, 1500, '2026-08-18');
      expect(b.todaySteps, 500);
    });

    test('phone restart keeps the steps already counted', () {
      final a = StepCounterState.update(null, 1000, '2026-08-18');
      final b = StepCounterState.update(a, 1500, '2026-08-18'); // 500 today
      final c = StepCounterState.update(b, 200, '2026-08-18'); // restarted, sensor at 200
      expect(c.todaySteps, 700);
    });

    test('a new day starts counting again', () {
      final a = StepCounterState.update(null, 1000, '2026-08-18');
      final b = StepCounterState.update(a, 1500, '2026-08-18');
      final c = StepCounterState.update(b, 1600, '2026-08-19');
      expect(c.todaySteps, 100);
    });
  });

  group('Calories from steps', () {
    test('8,000 steps for a 170 cm, 70 kg male is about 209 kcal', () {
      final kcal = ActivityCalculator.caloriesFromSteps(
          steps: 8000, heightCm: 170, weightKg: 70, gender: Gender.male);
      expect(kcal, 209);
    });

    test('0 steps burns 0 kcal', () {
      expect(
          ActivityCalculator.caloriesFromSteps(
              steps: 0, heightCm: 170, weightKg: 70, gender: Gender.female),
          0);
    });
  });
}
