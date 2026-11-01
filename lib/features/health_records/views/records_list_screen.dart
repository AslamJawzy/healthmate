import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../models/health_record.dart';
import '../viewmodels/health_record_viewmodel.dart';
import '../widgets/record_tile.dart';
import 'add_edit_record_screen.dart';

/// VIEW LAYER
/// Shows past health records with search by date and Day/Week/Month filters.
/// Swipe a record left to delete it. Tap a record to edit it.
class RecordsListScreen extends StatelessWidget {
  const RecordsListScreen({super.key});

  Future<void> _searchByDate(BuildContext context) async {
    final vm = context.read<HealthRecordViewModel>();
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.filterDate,
      firstDate: DateTime(2020),
      lastDate: AppDateUtils.today(),
      helpText: 'Search records by date',
    );
    if (picked != null) vm.searchByDate(picked);
  }

  Future<bool> _confirmDelete(BuildContext context, HealthRecord record) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Delete record?'),
        content: Text('The record for ${AppDateUtils.friendly(record.dateTime)} will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _delete(BuildContext context, HealthRecord record) async {
    final vm = context.read<HealthRecordViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final error = await vm.deleteRecord(record);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Record deleted'),
        action: error == null
            ? SnackBarAction(label: 'UNDO', onPressed: () => vm.restoreRecord(record))
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HealthRecordViewModel>();
    final records = vm.filteredRecords;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Records'),
        actions: [
          IconButton(
            tooltip: 'Search by date',
            icon: const Icon(Icons.event),
            onPressed: () => _searchByDate(context),
          ),
          if (vm.filter != RecordFilter.all)
            IconButton(
              tooltip: 'Clear filter',
              icon: const Icon(Icons.filter_alt_off),
              onPressed: vm.clearFilter,
            ),
        ],
      ),
      body: Column(
        children: [
          // ---------- Filter chips ----------
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: RecordFilter.values.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.label),
                    selected: vm.filter == f,
                    onSelected: (_) => vm.setFilter(f),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${vm.filterLabel}  •  ${records.length} record${records.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (vm.filter != RecordFilter.all)
                  TextButton.icon(
                    onPressed: () => _searchByDate(context),
                    icon: const Icon(Icons.edit_calendar, size: 18),
                    label: const Text('Change date'),
                  ),
              ],
            ),
          ),

          // ---------- List ----------
          Expanded(child: _buildList(context, vm, records)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, HealthRecordViewModel vm, List<HealthRecord> records) {
    if (vm.isLoading && vm.records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.errorMessage != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        message: vm.errorMessage!,
        action: FilledButton(onPressed: vm.loadRecords, child: const Text('Retry')),
      );
    }
    if (records.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No records found',
        message: vm.filter == RecordFilter.all
            ? 'Tap "Add Record" to create your first health record.'
            : 'There are no records for ${vm.filterLabel}.',
        action: vm.filter == RecordFilter.all
            ? null
            : OutlinedButton(onPressed: vm.clearFilter, child: const Text('Show all records')),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.loadRecords,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 96),
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return Dismissible(
            key: ValueKey(record.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onErrorContainer),
            ),
            confirmDismiss: (_) => _confirmDelete(context, record),
            onDismissed: (_) => _delete(context, record),
            child: RecordTile(
              record: record,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AddEditRecordScreen(record: record)),
              ),
            ),
          );
        },
      ),
    );
  }
}
