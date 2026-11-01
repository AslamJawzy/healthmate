import 'package:flutter/material.dart';

import '../dashboard/views/dashboard_screen.dart';
import '../food/views/food_log_screen.dart';
import '../health_records/views/add_edit_record_screen.dart';
import '../health_records/views/records_list_screen.dart';
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
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = AppTab.dashboard;

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
