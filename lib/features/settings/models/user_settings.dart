import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Used to estimate stride length and calories burned.
enum Gender { male, female, other }

extension GenderLabel on Gender {
  String get label {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }
}

/// MODEL: the user's personal settings (profile, daily goals and theme).
class UserSettings {
  final int stepsGoal;
  final int caloriesGoal;
  final int waterGoal;
  final int foodGoal;
  final ThemeMode themeMode;

  // Profile, used for the automatic step and calorie estimates.
  final int heightCm;
  final double weightKg;
  final Gender gender;
  final bool autoTrackSteps;

  const UserSettings({
    this.stepsGoal = DefaultGoals.steps,
    this.caloriesGoal = DefaultGoals.calories,
    this.waterGoal = DefaultGoals.water,
    this.foodGoal = DefaultGoals.food,
    this.themeMode = ThemeMode.system,
    this.heightCm = 170,
    this.weightKg = 70,
    this.gender = Gender.male,
    this.autoTrackSteps = true,
  });

  UserSettings copyWith({
    int? stepsGoal,
    int? caloriesGoal,
    int? waterGoal,
    int? foodGoal,
    ThemeMode? themeMode,
    int? heightCm,
    double? weightKg,
    Gender? gender,
    bool? autoTrackSteps,
  }) {
    return UserSettings(
      stepsGoal: stepsGoal ?? this.stepsGoal,
      caloriesGoal: caloriesGoal ?? this.caloriesGoal,
      waterGoal: waterGoal ?? this.waterGoal,
      foodGoal: foodGoal ?? this.foodGoal,
      themeMode: themeMode ?? this.themeMode,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      gender: gender ?? this.gender,
      autoTrackSteps: autoTrackSteps ?? this.autoTrackSteps,
    );
  }
}
