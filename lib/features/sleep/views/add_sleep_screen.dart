import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';
import '../models/sleep_record.dart';
import '../viewmodels/sleep_viewmodel.dart';

/// VIEW: log or edit one night of sleep using time pickers.
class AddSleepScreen extends StatefulWidget {
  final SleepRecord? record;

  const AddSleepScreen({super.key, this.record});

  @override
  State<AddSleepScreen> createState() => _AddSleepScreenState();
}

class _AddSleepScreenState extends State<AddSleepScreen> {
  late DateTime _date;
  late TimeOfDay _bedTime;
  late TimeOfDay _wakeTime;
  late int _quality;
  bool _saving = false;

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _date = r?.dateTime ?? AppDateUtils.today();
    _bedTime = r != null ? SleepRecord.textToTime(r.bedTime) : const TimeOfDay(hour: 22, minute: 30);
    _wakeTime = r != null ? SleepRecord.textToTime(r.wakeTime) : const TimeOfDay(hour: 6, minute: 0);
    _quality = r?.quality ?? 4;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: AppDateUtils.today(),
      helpText: 'Morning you woke up',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isBed) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isBed ? _bedTime : _wakeTime,
      helpText: isBed ? 'Bed time' : 'Wake-up time',
    );
    if (picked == null) return;
    setState(() {
      if (isBed) {
        _bedTime = picked;
      } else {
        _wakeTime = picked;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final error = await context.read<SleepViewModel>().save(
          id: widget.record?.id,
          date: _date,
          bedTime: _bedTime,
          wakeTime: _wakeTime,
          quality: _quality,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: errorColor));
      return;
    }
    messenger.showSnackBar(const SnackBar(content: Text('Sleep saved')));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = SleepRecord.calculateDuration(_bedTime, _wakeTime);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Sleep' : 'Log Sleep')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Woke up on'),
            subtitle: Text(AppDateUtils.friendly(_date)),
            onTap: _pickDate,
          ),
          ListTile(
            leading: const Icon(Icons.bedtime, color: AppColors.sleep),
            title: const Text('Went to bed'),
            subtitle: Text(_bedTime.format(context)),
            onTap: () => _pickTime(true),
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny, color: Colors.amber),
            title: const Text('Woke up'),
            subtitle: Text(_wakeTime.format(context)),
            onTap: () => _pickTime(false),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text('You slept', style: theme.textTheme.bodyMedium),
                Text(
                  SleepRecord.formatDuration(minutes),
                  style: theme.textTheme.displaySmall?.copyWith(color: AppColors.sleep, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('How well did you sleep?', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final value = i + 1;
              final selected = value == _quality;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _quality = value),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.sleep.withAlpha(50) : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(SleepRecord.qualityEmojis[i], style: const TextStyle(fontSize: 28)),
                      Text(SleepRecord.qualityLabels[i], style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: Text(_isEditing ? 'Update' : 'Save'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.sleep,
            ),
          ),
        ],
      ),
    );
  }
}
