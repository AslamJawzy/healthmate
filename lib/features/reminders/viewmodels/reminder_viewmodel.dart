import 'dart:math';

import 'package:flutter/material.dart';

import '../models/reminder_settings.dart';
import '../repositories/reminder_repository.dart';
import '../services/notification_service.dart';

/// Payloads tell the app what to open when a notification is tapped.
class ReminderPayload {
  ReminderPayload._();
  static const breathing = 'breathing';
  static const water = 'water';
  static const move = 'move';
  static const screenTime = 'screen_time';
}

/// Friendly messages for the screen time reminder. One is picked at random.
const screenTimeMessages = [
  "You've been on your phone for a while. Put it aside and rest your eyes 👀",
  'Time for a screen break. Look at something 6 metres away for 20 seconds.',
  'Phone down for 5 minutes? Stretch your neck and shoulders 🙆',
  'Too much screen time can affect your sleep. Take a short break 🌿',
  'Give your eyes a rest. Blink slowly and look out of a window.',
  'How about a short walk instead of scrolling? 🚶',
];

/// VIEWMODEL: reminder settings + scheduling of all notifications.
class ReminderViewModel extends ChangeNotifier {
  final ReminderRepository _repository;
  final NotificationService _notifications;
  final Random _random = Random();

  ReminderViewModel(this._repository, this._notifications);

  ReminderSettings _settings = const ReminderSettings();
  int _scheduledCount = 0;
  bool _loaded = false;

  ReminderSettings get settings => _settings;
  int get scheduledCount => _scheduledCount;
  bool get loaded => _loaded;

  String randomScreenTimeMessage() => screenTimeMessages[_random.nextInt(screenTimeMessages.length)];

  /// Loads settings and re-creates the schedule (keeps it in sync on every start).
  Future<void> load() async {
    try {
      _settings = await _repository.load();
      _loaded = true;
      notifyListeners();
      await reschedule();
    } catch (e) {
      debugPrint('Reminder load error: $e');
    }
  }

  Future<void> update(ReminderSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    try {
      await _repository.save(newSettings);
      await reschedule();
    } catch (e) {
      debugPrint('Reminder update error: $e');
    }
  }

  Future<bool> requestPermission() => _notifications.requestPermission();

  /// Cancels everything, then schedules the reminders that are switched on.
  Future<void> reschedule() async {
    final s = _settings;
    try {
      await _notifications.init();
      await _notifications.cancelAll();
      var count = 0;

      if (s.breathingEnabled) {
        const bodies = [
          'Start your day calm: 2 minutes of breathing before breakfast 🌅',
          'Lunch was 2 hours ago. Take 2 minutes to breathe and reset 🧘',
          'Wind down after dinner with a short breathing exercise 🌙',
        ];
        final times = s.breathingTimes;
        for (var i = 0; i < times.length; i++) {
          await _notifications.scheduleDaily(
            id: 100 + i,
            title: 'Time to breathe 🧘',
            body: bodies[i],
            time: times[i],
            payload: ReminderPayload.breathing,
          );
          count++;
        }
      }

      if (s.waterEnabled) {
        final times = s.waterTimes;
        for (var i = 0; i < times.length; i++) {
          await _notifications.scheduleDaily(
            id: 200 + i,
            title: 'Drink some water 💧',
            body: 'Stay hydrated. Have a glass of water now and log it in HealthMate.',
            time: times[i],
            payload: ReminderPayload.water,
          );
          count++;
        }
      }

      if (s.moveEnabled) {
        final times = s.moveTimes;
        for (var i = 0; i < times.length; i++) {
          await _notifications.scheduleDaily(
            id: 300 + i,
            title: 'Time to move 🚶',
            body: "You've been sitting for a while. Stand up and walk a little.",
            time: times[i],
            payload: ReminderPayload.move,
          );
          count++;
        }
      }

      if (s.screenTimeEnabled) {
        final times = s.screenTimeTimes;
        for (var i = 0; i < times.length; i++) {
          await _notifications.scheduleDaily(
            id: 400 + i,
            title: 'Screen time check 📱',
            body: randomScreenTimeMessage(),
            time: times[i],
            payload: ReminderPayload.screenTime,
          );
          count++;
        }
      }

      _scheduledCount = count;
      notifyListeners();
    } catch (e) {
      debugPrint('Reschedule error: $e');
    }
  }

  /// Sends a notification straight away (for testing and the demo video).
  Future<void> sendTest() async {
    await _notifications.init();
    await _notifications.showNow(
      id: 999,
      title: 'Time to breathe 🧘',
      body: 'This is a test reminder from HealthMate. Tap to start breathing.',
      payload: ReminderPayload.breathing,
    );
  }
}
