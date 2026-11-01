import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// SERVICE: the only class that talks to the flutter_local_notifications
/// plugin. Android itself delivers scheduled notifications, so the app
/// does NOT need to keep running in the background.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Called when the user taps a notification (payload says which one).
  void Function(String? payload)? onTap;

  static const _channelId = 'healthmate_reminders';
  static const _channelName = 'Health reminders';

  Future<void>? _initFuture;

  /// Safe to call many times: the plugin is only set up once, and every
  /// caller waits for that same setup to finish.
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    tz_data.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) => onTap?.call(response.payload),
    );
  }

  /// If the app was opened by tapping a notification, returns its payload.
  Future<String?> launchPayload() async {
    await init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  /// Android 13+ and iOS ask the user before showing notifications.
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return false;
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Breathing, water, movement and screen time reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Shows a notification every day at [time].
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    // Convert the phone's local time to an exact moment (UTC).
    // Sri Lanka has no daylight saving, so the daily time stays the same.
    final scheduled = tz.TZDateTime.from(next, tz.UTC);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _details,
      // Inexact = Android may deliver a few minutes late to save battery,
      // but it does not need the special "exact alarm" permission.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      payload: payload,
    );
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) {
    return _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
      payload: payload,
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<int> pendingCount() async => (await _plugin.pendingNotificationRequests()).length;
}
