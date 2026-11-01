import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../models/sleep_record.dart';
import '../viewmodels/sleep_viewmodel.dart';
import 'add_sleep_screen.dart';

/// VIEW: sleep tracker with last night, 7-night average and history.
class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});

  void _openForm(BuildContext context, {SleepRecord? record}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddSleepScreen(record: record)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SleepViewModel>();
    final theme = Theme.of(context);
    final lastNight = vm.lastNight;
    const goal = DefaultGoals.sleepMinutes;

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Tracker')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addSleep',
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.bedtime),
        label: const Text('Log Sleep'),
      ),
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            // ---------- Summary cards ----------
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    title: 'Last night',
                    value: lastNight?.durationText ?? '--',
                    subtitle: lastNight == null
                        ? 'Not logged yet'
                        : '${lastNight.bedTime} → ${lastNight.wakeTime}',
                    progress: lastNight == null ? 0 : lastNight.durationMinutes / goal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryTile(
                    title: '7-night average',
                    value: vm.weeklyAverageMinutes == 0
                        ? '--'
                        : SleepRecord.formatDuration(vm.weeklyAverageMinutes),
                    subtitle: 'Goal ${SleepRecord.formatDuration(goal)}',
                    progress: vm.weeklyAverageMinutes / goal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (lastNight == null)
              Card(
                color: AppColors.sleep.withAlpha(30),
                child: ListTile(
                  leading: const Icon(Icons.nights_stay, color: AppColors.sleep),
                  title: const Text('How did you sleep last night?'),
                  subtitle: const Text('Tap to log your bed time and wake time.'),
                  onTap: () => _openForm(context),
                ),
              ),
            const SizedBox(height: 8),
            Text('History', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),

            if (vm.isLoading && vm.records.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (vm.records.isEmpty)
              const EmptyState(
                icon: Icons.bedtime_off,
                title: 'No sleep logged yet',
                message: 'Tap "Log Sleep" to add your first night.',
              )
            else
              for (final r in vm.records)
                Dismissible(
                  key: ValueKey('sleep_${r.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: theme.colorScheme.errorContainer,
                    child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
                  ),
                  onDismissed: (_) {
                    final messenger = ScaffoldMessenger.of(context);
                    vm.delete(r);
                    messenger.hideCurrentSnackBar();
                    messenger.showSnackBar(SnackBar(
                      content: const Text('Sleep record deleted'),
                      action: SnackBarAction(label: 'UNDO', onPressed: () => vm.restore(r)),
                    ));
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.sleep.withAlpha(40),
                        child: Text(SleepRecord.qualityEmojis[r.quality - 1]),
                      ),
                      title: Text(AppDateUtils.friendly(r.dateTime)),
                      subtitle: Text('${r.bedTime} → ${r.wakeTime}  •  ${SleepRecord.qualityLabels[r.quality - 1]}'),
                      trailing: Text(
                        r.durationText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: r.durationMinutes >= goal ? AppColors.sleep : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => _openForm(context, record: r),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final double progress;

  const _SummaryTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: AppColors.sleep.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bedtime, color: AppColors.sleep, size: 20),
                const SizedBox(width: 6),
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.sleep, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                color: AppColors.sleep,
                backgroundColor: AppColors.sleep.withAlpha(40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
