import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../models/health_record.dart';

/// One row in the Records list: the date plus three coloured values.
class RecordTile extends StatelessWidget {
  final HealthRecord record;
  final VoidCallback onTap;

  const RecordTile({super.key, required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = AppDateUtils.isToday(record.dateTime);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    AppDateUtils.friendly(record.dateTime),
                    style: theme.textTheme.titleMedium,
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: const Text('Today'),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                  const Spacer(),
                  Icon(Icons.chevron_right, color: theme.colorScheme.outline),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Value(icon: AppIcons.steps, color: AppColors.steps, text: Fmt.number(record.steps)),
                  _Value(icon: AppIcons.calories, color: AppColors.calories, text: '${Fmt.number(record.calories)} kcal'),
                  _Value(icon: AppIcons.water, color: AppColors.water, text: '${Fmt.number(record.water)} ml'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Value({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
