import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../models/food_entry.dart';
import '../models/food_item.dart';
import '../viewmodels/food_viewmodel.dart';

/// VIEW: search the Sri Lankan food list, choose servings and meal,
/// and see the calories calculated before adding.
class AddFoodScreen extends StatefulWidget {
  final Meal? initialMeal;

  const AddFoodScreen({super.key, this.initialMeal});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load the full list when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodViewModel>().search('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showPortionSheet(FoodItem food) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PortionSheet(
        name: food.name,
        portion: food.portion,
        caloriesPerPortion: food.calories,
        initialMeal: widget.initialMeal ?? MealInfo.fromTime(DateTime.now()),
      ),
    );
    if (added == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _showCustomFoodDialog() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CustomFoodSheet(
        initialMeal: widget.initialMeal ?? MealInfo.fromTime(DateTime.now()),
      ),
    );
    if (added == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FoodViewModel>();
    final results = vm.searchResults;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Food')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search e.g. kottu, hoppers, dhal',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          vm.search('');
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (text) {
                vm.search(text);
                setState(() {}); // show / hide the clear button
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text("Can't find it? Add a custom food"),
            onTap: _showCustomFoodDialog,
          ),
          const Divider(height: 1),
          Expanded(
            child: results.isEmpty
                ? const Center(child: Text('No foods match your search'))
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final food = results[i];
                      final showHeader = i == 0 || results[i - 1].category != food.category;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                              child: Text(
                                food.category,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.food),
                              ),
                            ),
                          ListTile(
                            title: Text(food.name),
                            subtitle: Text(food.portion),
                            trailing: Text('${Fmt.number(food.calories)} kcal'),
                            onTap: () => _showPortionSheet(food),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to choose servings and meal for a listed food.
class _PortionSheet extends StatefulWidget {
  final String name;
  final String portion;
  final int caloriesPerPortion;
  final Meal initialMeal;

  const _PortionSheet({
    required this.name,
    required this.portion,
    required this.caloriesPerPortion,
    required this.initialMeal,
  });

  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
  double _servings = 1;
  late Meal _meal = widget.initialMeal;
  bool _saving = false;

  Future<void> _add() async {
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<FoodViewModel>().addFood(
          name: widget.name,
          portion: widget.portion,
          caloriesPerPortion: widget.caloriesPerPortion,
          servings: _servings,
          meal: _meal,
        );
    messenger.showSnackBar(SnackBar(content: Text(error ?? '${widget.name} added to ${_meal.label}')));
    navigator.pop(error == null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = (widget.caloriesPerPortion * _servings).round();
    final servingsText = _servings == _servings.roundToDouble() ? _servings.toInt().toString() : _servings.toString();

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.name, style: theme.textTheme.titleLarge),
          Text('${widget.portion} = ${Fmt.number(widget.caloriesPerPortion)} kcal', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Servings'),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: _servings > 0.5 ? () => setState(() => _servings -= 0.5) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 48,
                child: Text(servingsText, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              ),
              IconButton.filledTonal(
                onPressed: _servings < 10 ? () => setState(() => _servings += 0.5) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MealPicker(selected: _meal, onChanged: (m) => setState(() => _meal = m)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _add,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.food,
            ),
            child: Text('Add  •  ${Fmt.number(total)} kcal'),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to add a food that is not in the list.
class _CustomFoodSheet extends StatefulWidget {
  final Meal initialMeal;

  const _CustomFoodSheet({required this.initialMeal});

  @override
  State<_CustomFoodSheet> createState() => _CustomFoodSheetState();
}

class _CustomFoodSheetState extends State<_CustomFoodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _calories = TextEditingController();
  late Meal _meal = widget.initialMeal;

  @override
  void dispose() {
    _name.dispose();
    _calories.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<FoodViewModel>().addFood(
          name: _name.text.trim(),
          portion: '1 serving',
          caloriesPerPortion: int.parse(_calories.text),
          servings: 1,
          meal: _meal,
        );
    messenger.showSnackBar(SnackBar(content: Text(error ?? '${_name.text.trim()} added')));
    navigator.pop(error == null);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Custom food', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Food name', prefixIcon: Icon(Icons.fastfood)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a food name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _calories,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Calories', suffixText: 'kcal', prefixIcon: Icon(Icons.local_fire_department)),
              validator: (v) => Validators.goal(v, fieldName: 'Calories', min: 1, max: 5000),
            ),
            const SizedBox(height: 16),
            _MealPicker(selected: _meal, onChanged: (m) => setState(() => _meal = m)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _add,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: AppColors.food),
              child: const Text('Add food'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Breakfast / Lunch / Dinner / Snacks chips.
class _MealPicker extends StatelessWidget {
  final Meal selected;
  final ValueChanged<Meal> onChanged;

  const _MealPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Meal.values
          .map((m) => ChoiceChip(
                label: Text('${m.emoji} ${m.label}'),
                selected: m == selected,
                onSelected: (_) => onChanged(m),
              ))
          .toList(),
    );
  }
}
