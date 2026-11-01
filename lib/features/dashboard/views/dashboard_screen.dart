import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/metric.dart';
import '../../../core/utils/period.dart';
import '../../../core/widgets/metric_card.dart';
import '../../../core/widgets/period_selector.dart';
import '../../health_records/viewmodels/health_record_viewmodel.dart';
import '../../health_records/views/add_edit_record_screen.dart';
import '../../settings/viewmodels/settings_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/weekly_chart.dart';

/// VIEW LAYER
/// Summary of today's activity (Day by default), or a week / month.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _quickAddWater(BuildContext context, DateTime date, int ml) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<HealthRecordViewModel>().addWater(date, ml);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Added $ml ml of water 💧')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordsVm = context.watch<HealthRecordViewModel>();
    final dashVm = context.watch<DashboardViewModel>();
    final settings = context.watch<SettingsViewModel>();
    final theme = Theme.of(context);

    final summary = recordsVm.summaryFor(dashVm.period, dashVm.anchorDate);
    final isDay = dashVm.period == Period.day;
    final days = summary.daysInRange;

    // Goals scale with the period: a week's goal is 7 x the daily goal.
    final stepsGoal = settings.stepsGoal * days;
    final caloriesGoal = settings.caloriesGoal * days;
    final waterGoal = settings.waterGoal * days;

    String? avgText(int total, String unit) => isDay
        ? null
        : 'Avg ${Fmt.number(summary.averageOf(total))} $unit/day  •  ${summary.daysRecorded}/$days days logged';

    // The chart ends on the last day of the period, but never in the future.
    final today = AppDateUtils.today();
    final chartEnd = summary.range.end.isAfter(today) ? today : summary.range.end;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HealthMate'),
      ),
      body: RefreshIndicator(
        onRefresh: recordsVm.loadRecords,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Text(_greeting(), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Here is your health summary', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),

            // ---------- Day / Week / Month ----------
            Center(
              child: PeriodSelector(selected: dashVm.period, onChanged: dashVm.setPeriod),
            ),
            const SizedBox(height: 8),

            // ---------- Date navigation ----------
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => dashVm.shift(-1),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: dashVm.goToToday,
                    child: Text(
                      AppDateUtils.periodLabel(dashVm.period, dashVm.anchorDate),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: dashVm.canGoForward ? () => dashVm.shift(1) : null,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ---------- Prompt when the day has no record ----------
            if (isDay && summary.isEmpty) ...[
              Card(
                color: theme.colorScheme.primaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.add_task),
                  title: const Text('No record for this day yet'),
                  subtitle: const Text('Add your steps, calories and water.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditRecordScreen(initialDate: dashVm.anchorDate),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ---------- Metric cards ----------
            MetricCard(
              title: 'Steps',
              value: Fmt.number(summary.totalSteps),
              unit: 'steps',
              icon: AppIcons.steps,
              color: AppColors.steps,
              progress: summary.totalSteps / stepsGoal,
              subtitle: avgText(summary.totalSteps, 'steps') ?? 'Goal ${Fmt.number(stepsGoal)} steps',
            ),
            const SizedBox(height: 12),
            MetricCard(
              title: 'Calories Burned',
              value: Fmt.number(summary.totalCalories),
              unit: 'kcal',
              icon: AppIcons.calories,
              color: AppColors.calories,
              progress: summary.totalCalories / caloriesGoal,
              subtitle: avgText(summary.totalCalories, 'kcal') ?? 'Goal ${Fmt.number(caloriesGoal)} kcal',
            ),
            const SizedBox(height: 12),
            MetricCard(
              title: 'Water Intake',
              value: Fmt.number(summary.totalWater),
              unit: 'ml',
              icon: AppIcons.water,
              color: AppColors.water,
              progress: summary.totalWater / waterGoal,
              subtitle: avgText(summary.totalWater, 'ml') ?? 'Goal ${Fmt.number(waterGoal)} ml',
            ),

            // ---------- Quick add water (only for a single day) ----------
            if (isDay) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final ml in const [250, 500]) ...[
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => _quickAddWater(context, dashVm.anchorDate, ml),
                        icon: const Icon(AppIcons.water, color: AppColors.water),
                        label: Text('+$ml ml'),
                      ),
                    ),
                    if (ml == 250) const SizedBox(width: 12),
                  ],
                ],
              ),
            ],

            // ---------- Edit shortcut when a day record exists ----------
            if (isDay && !summary.isEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  final record = recordsVm.recordForDate(dashVm.anchorDate);
                  if (record == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AddEditRecordScreen(record: record)),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit this day'),
              ),
            ],

            // ---------- Weekly chart ----------
            const SizedBox(height: 16),
            WeeklyChart(
              endDate: chartEnd,
              recordFor: recordsVm.recordForDate,
              goalFor: (metric) {
                switch (metric) {
                  case Metric.steps:
                    return settings.stepsGoal;
                  case Metric.calories:
                    return settings.caloriesGoal;
                  case Metric.water:
                    return settings.waterGoal;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
