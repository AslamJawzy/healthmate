import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/utils/validators.dart';
import '../models/health_record.dart';
import '../viewmodels/health_record_viewmodel.dart';

/// VIEW LAYER
/// One screen used for both adding a new record and editing an existing one.
/// If [record] is null we are adding, otherwise we are editing.
class AddEditRecordScreen extends StatefulWidget {
  final HealthRecord? record;
  final DateTime? initialDate;

  const AddEditRecordScreen({super.key, this.record, this.initialDate});

  bool get isEditing => record != null;

  @override
  State<AddEditRecordScreen> createState() => _AddEditRecordScreenState();
}

class _AddEditRecordScreenState extends State<AddEditRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stepsController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _waterController;
  late DateTime _selectedDate;
  String? _dateError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _selectedDate = r?.dateTime ?? widget.initialDate ?? AppDateUtils.today();
    _stepsController = TextEditingController(text: r?.steps.toString() ?? '');
    _caloriesController = TextEditingController(text: r?.calories.toString() ?? '');
    _waterController = TextEditingController(text: r?.water.toString() ?? '');
  }

  @override
  void dispose() {
    // Always dispose controllers to free memory.
    _stepsController.dispose();
    _caloriesController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: AppDateUtils.today(), // future dates are blocked
      helpText: 'Select record date',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateError = null;
      });
    }
  }

  Future<void> _save() async {
    // 1. Validate the date and every text field.
    final dateError = Validators.notFutureDate(_selectedDate, AppDateUtils.today());
    setState(() => _dateError = dateError);
    final fieldsValid = _formKey.currentState!.validate();
    if (!fieldsValid || dateError != null) return;

    // 2. Build the record from the form values.
    final record = HealthRecord(
      id: widget.record?.id,
      date: AppDateUtils.toDbString(_selectedDate),
      steps: int.parse(_stepsController.text.trim()),
      calories: int.parse(_caloriesController.text.trim()),
      water: int.parse(_waterController.text.trim()),
    );

    // 3. Ask the ViewModel to save it.
    setState(() => _isSaving = true);
    final viewModel = context.read<HealthRecordViewModel>();
    final error = widget.isEditing
        ? await viewModel.updateRecord(record)
        : await viewModel.addRecord(record);

    if (!mounted) return;
    setState(() => _isSaving = false);

    // 4. Show the result to the user.
    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(widget.isEditing ? 'Record updated' : 'Record added')),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HealthRecordViewModel>();
    final existing = viewModel.recordForDate(_selectedDate);
    final dateAlreadyUsed =
        existing != null && existing.id != widget.record?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Record' : 'Add Record'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ---------- Date ----------
              InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: const Icon(Icons.calendar_today),
                    errorText: _dateError,
                  ),
                  child: Text(AppDateUtils.friendly(_selectedDate)),
                ),
              ),
              if (dateAlreadyUsed)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.tertiary),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text('A record already exists for this date.'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => AddEditRecordScreen(record: existing),
                            ),
                          );
                        },
                        child: const Text('Edit it'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // ---------- Steps ----------
              _NumberField(
                controller: _stepsController,
                label: 'Steps walked',
                suffix: 'steps',
                icon: AppIcons.steps,
                color: AppColors.steps,
                validator: Validators.steps,
              ),
              const SizedBox(height: 16),

              // ---------- Calories ----------
              _NumberField(
                controller: _caloriesController,
                label: 'Calories burned',
                suffix: 'kcal',
                icon: AppIcons.calories,
                color: AppColors.calories,
                validator: Validators.calories,
              ),
              const SizedBox(height: 16),

              // ---------- Water ----------
              _NumberField(
                controller: _waterController,
                label: 'Water intake',
                suffix: 'ml',
                icon: AppIcons.water,
                color: AppColors.water,
                validator: Validators.water,
                isLast: true,
              ),
              const SizedBox(height: 28),

              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(widget.isEditing ? 'Update Record' : 'Save Record'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Private reusable number input with a coloured icon.
class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;
  final Color color;
  final FormFieldValidator<String> validator;
  final bool isLast;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
    required this.color,
    required this.validator,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
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
