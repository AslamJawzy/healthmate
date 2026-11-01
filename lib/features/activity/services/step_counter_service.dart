import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/step_counter_state.dart';

/// SERVICE: the only class that talks to the step sensor (pedometer plugin),
/// the activity permission (permission_handler) and stores the step state.
class StepCounterService {
  static const _kDate = 'step_date';
  static const _kBaseline = 'step_baseline';
  static const _kCarried = 'step_carried';
  static const _kLast = 'step_last_sensor';

  StreamSubscription<StepCount>? _subscription;

  /// Android 10+ asks the user for "Physical activity" permission.
  Future<bool> requestPermission() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  /// Starts listening. [onReading] receives each raw sensor value,
  /// [onError] is called if the phone has no step sensor.
  void start({
    required void Function(int sensorSteps) onReading,
    required void Function(Object error) onError,
  }) {
    _subscription?.cancel();
    _subscription = Pedometer.stepCountStream.listen(
      (event) => onReading(event.steps),
      onError: onError,
      cancelOnError: false,
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<StepCounterState?> loadState() async {
    try {
      final p = await SharedPreferences.getInstance();
      final date = p.getString(_kDate);
      if (date == null) return null;
      return StepCounterState(
        date: date,
        baseline: p.getInt(_kBaseline) ?? 0,
        carried: p.getInt(_kCarried) ?? 0,
        lastSensor: p.getInt(_kLast) ?? 0,
      );
    } catch (e) {
      debugPrint('Step state load error: $e');
      return null;
    }
  }

  Future<void> saveState(StepCounterState s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kDate, s.date);
    await p.setInt(_kBaseline, s.baseline);
    await p.setInt(_kCarried, s.carried);
    await p.setInt(_kLast, s.lastSensor);
  }
}
