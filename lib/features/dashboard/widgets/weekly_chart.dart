import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/metric.dart';
import '../../health_records/models/health_record.dart';

/// Bar chart of the last 7 days for one metric (Steps / Calories / Water).
/// A dashed line shows the daily goal so the user can compare quickly.
class WeeklyChart extends StatefulWidget {
  final DateTime endDate; // last day shown on the chart
  final HealthRecord? Function(DateTime day) recordFor;
  final int Function(Metric metric) goalFor;

  const WeeklyChart({
    super.key,
    required this.endDate,
    required this.recordFor,
    required this.goalFor,
  });

  @override
  State<WeeklyChart> createState() => _WeeklyChartState();
}

class _WeeklyChartState extends State<WeeklyChart> {
  Metric _metric = Metric.steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final end = widget.endDate;
    final days = List.generate(7, (i) => DateTime(end.year, end.month, end.day - 6 + i));
    final values = days.map((d) {
      final r = widget.recordFor(d);
      return r == null ? 0 : _metric.valueOf(r);
    }).toList();
    final goal = widget.goalFor(_metric);
    final maxValue = max(values.reduce(max), goal);
    final maxY = maxValue == 0 ? 1.0 : maxValue * 1.15;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Last 7 days', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  'Avg ${Fmt.number(values.reduce((a, b) => a + b) ~/ 7)} ${_metric.unit}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: Metric.values.map((m) {
                return ChoiceChip(
                  avatar: Icon(m.icon, size: 18, color: m.color),
                  label: Text(m.label),
                  selected: _metric == m,
                  onSelected: (_) => setState(() => _metric = m),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= days.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('E').format(days[i]).substring(0, 2),
                              style: theme.textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: goal.toDouble(),
                        color: _metric.color.withAlpha(150),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                      ),
                    ],
                  ),
                  barGroups: List.generate(7, (i) {
                    final reached = values[i] >= goal;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i].toDouble(),
                          width: 18,
                          color: reached ? _metric.color : _metric.color.withAlpha(140),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Dashed line = daily goal (${Fmt.number(goal)} ${_metric.unit})',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
