import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../settings/viewmodels/settings_viewmodel.dart';
import '../models/food_entry.dart';
import '../viewmodels/food_viewmodel.dart';
import 'add_food_screen.dart';

/// VIEW: food diary for one day, grouped by meal, with total calories eaten.
class FoodLogScreen extends StatelessWidget {
  const FoodLogScreen({super.key});

  Future<void> _openAddFood(BuildContext context, {Meal? meal}) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddFoodScreen(initialMeal: meal)),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final vm = context.read<FoodViewModel>();
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.selectedDate,
      firstDate: DateTime(2020),
      lastDate: AppDateUtils.today(),
    );
    if (picked != null) vm.setDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FoodViewModel>();
    final goal = context.watch<SettingsViewModel>().foodGoal;
    final theme = Theme.of(context);
    final total = vm.totalCalories;
    final progress = goal == 0 ? 0.0 : (total / goal).clamp(0.0, 1.0);
    final over = total > goal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Diary'),
        actions: [
          IconButton(
            tooltip: 'Pick a date',
            icon: const Icon(Icons.event),
            onPressed: () => _pickDate(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addFood',
        onPressed: () => _openAddFood(context),
        icon: const Icon(Icons.restaurant),
        label: const Text('Add Food'),
      ),
      body: RefreshIndicator(
        onRefresh: vm.loadEntries,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          children: [
            // ---------- Day navigation ----------
            Row(
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => vm.changeDay(-1)),
                Expanded(
                  child: Text(
                    AppDateUtils.isToday(vm.selectedDate)
                        ? 'Today - ${AppDateUtils.headline(vm.selectedDate)}'
                        : AppDateUtils.friendly(vm.selectedDate),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: AppDateUtils.isToday(vm.selectedDate) ? null : () => vm.changeDay(1),
                ),
              ],
            ),

            // ---------- Calories eaten summary ----------
            Card(
              elevation: 0,
              color: AppColors.food.withAlpha(26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.restaurant, color: AppColors.food),
                        const SizedBox(width: 8),
                        Text('Calories eaten', style: theme.textTheme.titleSmall),
                        const Spacer(),
                        Text(
                          '${Fmt.number(total)} / ${Fmt.number(goal)} kcal',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.food,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        color: over ? AppColors.calories : AppColors.food,
                        backgroundColor: AppColors.food.withAlpha(40),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      over
                          ? '${Fmt.number(total - goal)} kcal over your daily target'
                          : '${Fmt.number(goal - total)} kcal left for today',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            if (vm.errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(vm.errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
              ),

            // ---------- One section per meal ----------
            for (final meal in Meal.values) _MealSection(meal: meal, onAdd: () => _openAddFood(context, meal: meal)),

            const SizedBox(height: 8),
            Text(
              'Calorie values are approximate, based on typical Sri Lankan portions.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  final Meal meal;
  final VoidCallback onAdd;

  const _MealSection({required this.meal, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FoodViewModel>();
    final entries = vm.entriesFor(meal);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          ListTile(
            leading: Text(meal.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(meal.label, style: theme.textTheme.titleMedium),
            subtitle: Text('${Fmt.number(vm.caloriesFor(meal))} kcal'),
            trailing: IconButton(
              tooltip: 'Add to ${meal.label}',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onAdd,
            ),
          ),
          for (final entry in entries)
            Dismissible(
              key: ValueKey('food_${entry.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                color: theme.colorScheme.errorContainer,
                child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
              ),
              onDismissed: (_) {
                final messenger = ScaffoldMessenger.of(context);
                vm.deleteEntry(entry);
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(SnackBar(
                  content: Text('${entry.foodName} removed'),
                  action: SnackBarAction(label: 'UNDO', onPressed: () => vm.restoreEntry(entry)),
                ));
              },
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 56, right: 16),
                title: Text(entry.foodName),
                subtitle: Text(entry.servingText),
                trailing: Text('${Fmt.number(entry.calories)} kcal'),
              ),
            ),
        ],
      ),
    );
  }
}
