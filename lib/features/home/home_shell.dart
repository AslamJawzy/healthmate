import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../breathing/views/breathing_screen.dart';
import '../dashboard/views/dashboard_screen.dart';
import '../food/views/food_log_screen.dart';
import '../health_records/views/add_edit_record_screen.dart';
import '../health_records/views/records_list_screen.dart';
import '../reminders/services/notification_service.dart';
import '../reminders/viewmodels/reminder_viewmodel.dart';
import '../reminders/views/screen_time_dialog.dart';
import '../settings/views/settings_screen.dart';
import '../sleep/views/sleep_screen.dart';

/// Tab positions, so other screens can switch tabs by name.
class AppTab {
  AppTab._();
  static const int dashboard = 0;
  static const int records = 1;
  static const int food = 2;
  static const int sleep = 3;
  static const int settings = 4;
}

/// The main screen with the bottom navigation bar.
/// IndexedStack keeps each tab alive, so scroll positions are not lost.
///
/// It also:
///  - opens the right screen when a reminder notification is tapped
///  - shows the screen time pop-up after 1 hour of continuous use
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  static const _screenTimeLimit = Duration(hours: 1);

  int _currentIndex = AppTab.dashboard;
  DateTime _sessionStart = DateTime.now();
  Timer? _screenTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // listen for app pause / resume
    NotificationService.instance.onTap = _handleNotificationTap;
    _screenTimer = Timer.periodic(const Duration(minutes: 1), (_) => _checkScreenTime());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Ask for notification permission once reminders are switched on.
      final reminders = context.read<ReminderViewModel>();
      if (reminders.settings.anyEnabled) await reminders.requestPermission();
      // The app may have been opened by tapping a notification.
      final payload = await NotificationService.instance.launchPayload();
      _handleNotificationTap(payload);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _screenTimer?.cancel();
    super.dispose();
  }

  /// Restart the timer whenever the user comes back to the app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sessionStart = DateTime.now();
  }

  void _checkScreenTime() {
    if (!mounted) return;
    final reminders = context.read<ReminderViewModel>();
    if (!reminders.settings.screenTimeEnabled) return;
    if (DateTime.now().difference(_sessionStart) >= _screenTimeLimit) {
      _sessionStart = DateTime.now(); // next pop-up in another hour
      showScreenTimeDialog(context, reminders.randomScreenTimeMessage());
    }
  }

  void _handleNotificationTap(String? payload) {
    if (!mounted || payload == null) return;
    switch (payload) {
      case ReminderPayload.breathing:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BreathingScreen()));
        break;
      case ReminderPayload.water:
      case ReminderPayload.move:
        _goTo(AppTab.dashboard);
        break;
      case ReminderPayload.screenTime:
        showScreenTimeDialog(context, context.read<ReminderViewModel>().randomScreenTimeMessage());
        break;
    }
  }

  void _goTo(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(onOpenTab: _goTo),
      const RecordsListScreen(),
      const FoodLogScreen(),
      const SleepScreen(),
      const SettingsScreen(),
    ];

    // The Add Record button only makes sense on Dashboard and Records.
    // Food and Sleep have their own buttons.
    final showFab = _currentIndex == AppTab.dashboard || _currentIndex == AppTab.records;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              heroTag: 'addRecord',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddEditRecordScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Record'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Food',
          ),
          NavigationDestination(
            icon: Icon(Icons.bedtime_outlined),
            selectedIcon: Icon(Icons.bedtime),
            label: 'Sleep',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
