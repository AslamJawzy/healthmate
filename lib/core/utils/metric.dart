import 'package:flutter/material.dart';

import '../../features/health_records/models/health_record.dart';
import '../theme/app_colors.dart';

/// The three health metrics stored in a HealthRecord.
/// Keeping label, unit, colour and icon together keeps the UI consistent.
enum Metric { steps, calories, water }

extension MetricInfo on Metric {
  String get label {
    switch (this) {
      case Metric.steps:
        return 'Steps';
      case Metric.calories:
        return 'Calories';
      case Metric.water:
        return 'Water';
    }
  }

  String get unit {
    switch (this) {
      case Metric.steps:
        return 'steps';
      case Metric.calories:
        return 'kcal';
      case Metric.water:
        return 'ml';
    }
  }

  Color get color {
    switch (this) {
      case Metric.steps:
        return AppColors.steps;
      case Metric.calories:
        return AppColors.calories;
      case Metric.water:
        return AppColors.water;
    }
  }

  IconData get icon {
    switch (this) {
      case Metric.steps:
        return AppIcons.steps;
      case Metric.calories:
        return AppIcons.calories;
      case Metric.water:
        return AppIcons.water;
    }
  }

  int valueOf(HealthRecord record) {
    switch (this) {
      case Metric.steps:
        return record.steps;
      case Metric.calories:
        return record.calories;
      case Metric.water:
        return record.water;
    }
  }
}
