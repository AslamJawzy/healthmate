import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../breathing/views/breathing_screen.dart';
import '../../food/viewmodels/food_viewmodel.dart';
import '../../settings/viewmodels/settings_viewmodel.dart';
import '../../sleep/viewmodels/sleep_viewmodel.dart';

/// Dashboard cards for today's food, last night's sleep and a
/// shortcut to the breathing exercise.
class WellnessSection extends StatelessWidget {
  final int caloriesBurnedToday;
  final VoidCallback onOpenFood;
  final VoidCallback onOpenSleep;

  const WellnessSection({
    super.key,
    required this.caloriesBurnedToday,
    required this.onOpenFood,
    required this.onOpenSleep,
  });

  @override
  Widget build(BuildContext context) {
    final eaten = context.watch<FoodViewModel>().todayTotal;
    final foodGoal = context.watch<SettingsViewModel>().foodGoal;
    final lastNight = context.watch<SleepViewModel>().lastNight;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today\'s wellness', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MiniCard(
                icon: Icons.restaurant,
                color: AppColors.food,
                title: 'Food eaten',
                value: '${Fmt.number(eaten)} kcal',
                subtitle: 'of ${Fmt.number(foodGoal)}  •  burned ${Fmt.number(caloriesBurnedToday)}',
                onTap: onOpenFood,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniCard(
                icon: Icons.bedtime,
                color: AppColors.sleep,
                title: 'Last night',
                value: lastNight?.durationText ?? 'Not logged',
                subtitle: lastNight == null
                    ? 'Tap to log sleep'
                    : (lastNight.durationMinutes >= DefaultGoals.sleepMinutes ? 'Goal reached 🎉' : 'Goal 8h'),
                onTap: onOpenSleep,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: AppColors.breathing.withAlpha(30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const CircleAvatar(
              backgroundColor: AppColors.breathing,
              child: Icon(Icons.self_improvement, color: Colors.white),
            ),
            title: const Text('Breathing exercise'),
            subtitle: const Text('Take 2 minutes to relax and reset'),
            trailing: const Icon(Icons.play_circle_fill, color: AppColors.breathing, size: 32),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BreathingScreen()),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  const _MiniCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: color.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 6),
                  Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
