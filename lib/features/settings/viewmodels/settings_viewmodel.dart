import 'package:flutter/material.dart';

import '../models/user_settings.dart';
import '../repositories/settings_repository.dart';

/// VIEWMODEL: holds the current settings and saves changes.
/// The whole app listens to this for the theme (light / dark).
class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _repository;

  SettingsViewModel(this._repository);

  UserSettings _settings = const UserSettings();

  UserSettings get settings => _settings;
  int get stepsGoal => _settings.stepsGoal;
  int get caloriesGoal => _settings.caloriesGoal;
  int get waterGoal => _settings.waterGoal;
  ThemeMode get themeMode => _settings.themeMode;

  Future<void> load() async {
    try {
      _settings = await _repository.load();
      notifyListeners();
    } catch (e) {
      debugPrint('Settings load error: $e'); // keep the defaults
    }
  }

  Future<String?> updateGoals({
    required int steps,
    required int calories,
    required int water,
  }) async {
    try {
      await _repository.saveGoals(steps: steps, calories: calories, water: water);
      _settings = _settings.copyWith(
        stepsGoal: steps,
        caloriesGoal: calories,
        waterGoal: water,
      );
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Save goals error: $e');
      return 'Could not save your goals.';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners(); // update the UI straight away
    try {
      await _repository.saveThemeMode(mode);
    } catch (e) {
      debugPrint('Save theme error: $e');
    }
  }
}
