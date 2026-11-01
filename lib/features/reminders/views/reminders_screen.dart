import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../models/reminder_settings.dart';
import '../viewmodels/reminder_viewmodel.dart';
import 'screen_time_dialog.dart';

/// VIEW: turn reminders on/off and set the daily routine they are based on.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  Future<void> _pickTime(
    BuildContext context,
    TimeOfDay current,
    String help,
    ReminderSettings Function(TimeOfDay picked) apply,
  ) async {
    final vm = context.read<ReminderViewModel>();
    final picked = await showTimePicker(context: context, initialTime: current, helpText: help);
    if (picked != null) await vm.update(apply(picked));
  }

  String _times(BuildContext context, List<TimeOfDay> times) {
    if (times.isEmpty) return 'No times between wake-up and bed time';
    if (times.length <= 3) return times.map((t) => t.format(context)).join(', ');
    return '${times.length} times, ${times.first.format(context)} to ${times.last.format(context)}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReminderViewModel>();
    final s = vm.settings;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ---------- Reminder switches ----------
          _SectionTitle('Reminders'),
          SwitchListTile(
            secondary: const Icon(Icons.self_improvement, color: AppColors.breathing),
            title: const Text('Breathing exercise'),
            subtitle: Text('Before breakfast and 2 hours after lunch and dinner\n${_times(context, s.breathingTimes)}'),
            isThreeLine: true,
            value: s.breathingEnabled,
            onChanged: (v) => vm.update(s.copyWith(breathingEnabled: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.water_drop, color: AppColors.water),
            title: const Text('Drink water'),
            subtitle: Text('Every 1.5 hours\n${_times(context, s.waterTimes)}'),
            isThreeLine: true,
            value: s.waterEnabled,
            onChanged: (v) => vm.update(s.copyWith(waterEnabled: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.directions_walk, color: AppColors.steps),
            title: const Text('Move a little'),
            subtitle: Text('Every hour until bed time\n${_times(context, s.moveTimes)}'),
            isThreeLine: true,
            value: s.moveEnabled,
            onChanged: (v) => vm.update(s.copyWith(moveEnabled: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.phone_android, color: AppColors.calories),
            title: const Text('Screen time check'),
            subtitle: Text('Every hour (at half past), plus a pop-up after 1 hour of using HealthMate\n${_times(context, s.screenTimeTimes)}'),
            isThreeLine: true,
            value: s.screenTimeEnabled,
            onChanged: (v) => vm.update(s.copyWith(screenTimeEnabled: v)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '${vm.scheduledCount} reminders scheduled each day',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const Divider(height: 32),

          // ---------- Daily routine ----------
          _SectionTitle('Your daily routine'),
          _TimeTile(
            icon: Icons.wb_sunny,
            label: 'Wake-up time',
            time: s.wakeTime,
            onTap: () => _pickTime(context, s.wakeTime, 'Wake-up time', (t) => s.copyWith(wakeTime: t)),
          ),
          _TimeTile(
            icon: Icons.free_breakfast,
            label: 'Breakfast',
            time: s.breakfastTime,
            onTap: () => _pickTime(context, s.breakfastTime, 'Breakfast time', (t) => s.copyWith(breakfastTime: t)),
          ),
          _TimeTile(
            icon: Icons.lunch_dining,
            label: 'Lunch',
            time: s.lunchTime,
            onTap: () => _pickTime(context, s.lunchTime, 'Lunch time', (t) => s.copyWith(lunchTime: t)),
          ),
          _TimeTile(
            icon: Icons.dinner_dining,
            label: 'Dinner',
            time: s.dinnerTime,
            onTap: () => _pickTime(context, s.dinnerTime, 'Dinner time', (t) => s.copyWith(dinnerTime: t)),
          ),
          _TimeTile(
            icon: Icons.bedtime,
            label: 'Bed time (no reminders after this)',
            time: s.sleepTime,
            onTap: () => _pickTime(context, s.sleepTime, 'Bed time', (t) => s.copyWith(sleepTime: t)),
          ),
          const Divider(height: 32),

          // ---------- Testing ----------
          _SectionTitle('Try it now'),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Send a test notification'),
            subtitle: const Text('Tap the notification to open the breathing exercise'),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final granted = await vm.requestPermission();
              if (!granted) {
                messenger.showSnackBar(const SnackBar(
                  content: Text('Please allow notifications for HealthMate in your phone settings.'),
                ));
                return;
              }
              await vm.sendTest();
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone_android),
            title: const Text('Show the screen time pop-up'),
            onTap: () => showScreenTimeDialog(context, vm.randomScreenTimeMessage()),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeTile({required this.icon, required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(time.format(context), style: Theme.of(context).textTheme.titleMedium),
      onTap: onTap,
    );
  }
}
