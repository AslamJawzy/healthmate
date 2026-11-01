import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../viewmodels/settings_viewmodel.dart';

/// VIEW: lets the user change daily goals and the app theme.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _steps;
  late final TextEditingController _calories;
  late final TextEditingController _water;

  @override
  void initState() {
    super.initState();
    final vm = context.read<SettingsViewModel>();
    _steps = TextEditingController(text: vm.stepsGoal.toString());
    _calories = TextEditingController(text: vm.caloriesGoal.toString());
    _water = TextEditingController(text: vm.waterGoal.toString());
  }

  @override
  void dispose() {
    _steps.dispose();
    _calories.dispose();
    _water.dispose();
    super.dispose();
  }

  Future<void> _saveGoals() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus(); // hide the keyboard
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<SettingsViewModel>().updateGoals(
          steps: int.parse(_steps.text),
          calories: int.parse(_calories.text),
          water: int.parse(_water.text),
        );
    messenger.showSnackBar(SnackBar(content: Text(error ?? 'Goals saved')));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------- Daily goals ----------
          Text('Daily goals', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Used for the progress rings and the chart on the Dashboard.',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _goalField(_steps, 'Steps goal', 'steps', AppIcons.steps, AppColors.steps,
                    (v) => Validators.goal(v, fieldName: 'Steps goal', min: 500, max: Validators.maxSteps)),
                const SizedBox(height: 12),
                _goalField(_calories, 'Calories burned goal', 'kcal', AppIcons.calories, AppColors.calories,
                    (v) => Validators.goal(v, fieldName: 'Calories goal', min: 50, max: Validators.maxCalories)),
                const SizedBox(height: 12),
                _goalField(_water, 'Water goal', 'ml', AppIcons.water, AppColors.water,
                    (v) => Validators.goal(v, fieldName: 'Water goal', min: 250, max: Validators.maxWater)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _saveGoals,
                  icon: const Icon(Icons.flag),
                  label: const Text('Save goals'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ),
          ),
          const Divider(height: 40),

          // ---------- Appearance ----------
          Text('Appearance', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('System')),
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Dark')),
            ],
            selected: {vm.themeMode},
            onSelectionChanged: (s) => vm.setThemeMode(s.first),
          ),
        ],
      ),
    );
  }

  Widget _goalField(
    TextEditingController controller,
    String label,
    String suffix,
    IconData icon,
    Color color,
    FormFieldValidator<String> validator,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        prefixIcon: Icon(icon, color: color),
      ),
      validator: validator,
    );
  }
}
