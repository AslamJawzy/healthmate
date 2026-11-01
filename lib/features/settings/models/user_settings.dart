import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// MODEL: the user's personal settings (daily goals and theme).
class UserSettings {
  final int stepsGoal;
  final int caloriesGoal;
  final int waterGoal;
  final ThemeMode themeMode;

  const UserSettings({
    this.stepsGoal = DefaultGoals.steps,
    this.caloriesGoal = DefaultGoals.calories,
    this.waterGoal = DefaultGoals.water,
    this.themeMode = ThemeMode.system,
  });

  UserSettings copyWith({
    int? stepsGoal,
    int? caloriesGoal,
    int? waterGoal,
    ThemeMode? themeMode,
  }) {
    return UserSettings(
      stepsGoal: stepsGoal ?? this.stepsGoal,
      caloriesGoal: caloriesGoal ?? this.caloriesGoal,
      waterGoal: waterGoal ?? this.waterGoal,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
