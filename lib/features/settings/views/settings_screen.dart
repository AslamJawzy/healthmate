import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../activity/viewmodels/step_tracker_viewmodel.dart';
import '../../reminders/views/reminders_screen.dart';
import '../models/user_settings.dart';
import '../viewmodels/settings_viewmodel.dart';

/// VIEW: lets the user change their profile, daily goals and the app theme.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileKey = GlobalKey<FormState>();
  late final TextEditingController _height;
  late final TextEditingController _weight;
  Gender _gender = Gender.male;
  bool _filled = false; // fields filled from saved settings yet?
  late final TextEditingController _steps;
  late final TextEditingController _calories;
  late final TextEditingController _water;
  late final TextEditingController _food;

  @override
  void initState() {
    super.initState();
    _height = TextEditingController();
    _weight = TextEditingController();
    _steps = TextEditingController();
    _calories = TextEditingController();
    _water = TextEditingController();
    _food = TextEditingController();
  }

  /// Settings load from storage after the screen is created, so the
  /// fields are filled once the saved values are available.
  void _fillFields(SettingsViewModel vm) {
    _height.text = vm.heightCm.toString();
    _weight.text = vm.weightKg % 1 == 0 ? vm.weightKg.toInt().toString() : vm.weightKg.toString();
    _gender = vm.gender;
    _steps.text = vm.stepsGoal.toString();
    _calories.text = vm.caloriesGoal.toString();
    _water.text = vm.waterGoal.toString();
    _food.text = vm.foodGoal.toString();
    _filled = true;
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _steps.dispose();
    _calories.dispose();
    _water.dispose();
    _food.dispose();
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
          food: int.parse(_food.text),
        );
    messenger.showSnackBar(SnackBar(content: Text(error ?? 'Goals saved')));
  }

  Future<void> _saveProfile() async {
    if (!_profileKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<SettingsViewModel>().updateProfile(
          heightCm: int.parse(_height.text),
          weightKg: double.parse(_weight.text),
          gender: _gender,
        );
    messenger.showSnackBar(SnackBar(content: Text(error ?? 'Profile saved')));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final tracker = context.watch<StepTrackerViewModel>();
    final theme = Theme.of(context);
    if (vm.loaded && !_filled) _fillFields(vm);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------- Reminders ----------
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active),
              title: const Text('Reminders'),
              subtitle: const Text('Breathing, water, move and screen time'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RemindersScreen()),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ---------- Profile ----------
          Text('Your profile', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Used to estimate calories burned from your steps.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Form(
            key: _profileKey,
            child: Column(
              children: [
                SegmentedButton<Gender>(
                  segments: Gender.values
                      .map((g) => ButtonSegment<Gender>(value: g, label: Text(g.label)))
                      .toList(),
                  selected: {_gender},
                  onSelectionChanged: (s) => setState(() => _gender = s.first),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _height,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Height',
                          suffixText: 'cm',
                          prefixIcon: Icon(Icons.height),
                        ),
                        validator: Validators.height,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weight,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Weight',
                          suffixText: 'kg',
                          prefixIcon: Icon(Icons.monitor_weight_outlined),
                        ),
                        validator: Validators.weight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.person),
                  label: const Text('Save profile'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(AppIcons.steps, color: AppColors.steps),
            title: const Text('Count steps automatically'),
            subtitle: Text(tracker.statusText),
            value: vm.autoTrackSteps,
            onChanged: (on) async {
              await vm.setAutoTrackSteps(on);
              if (on) {
                await tracker.start();
              } else {
                tracker.stop();
              }
            },
          ),
          const Divider(height: 32),

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
                const SizedBox(height: 12),
                _goalField(_food, 'Food calories target', 'kcal', Icons.restaurant, AppColors.food,
                    (v) => Validators.goal(v, fieldName: 'Food target', min: 800, max: 6000)),
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
