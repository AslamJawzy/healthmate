import 'package:flutter/material.dart';

import '../../../core/utils/app_date_utils.dart';
import '../models/food_entry.dart';
import '../models/food_item.dart';
import '../repositories/food_repository.dart';

/// VIEWMODEL: food diary for the selected day + food search.
class FoodViewModel extends ChangeNotifier {
  final FoodRepository _repository;

  FoodViewModel(this._repository);

  DateTime _selectedDate = AppDateUtils.today();
  List<FoodEntry> _entries = [];
  List<FoodItem> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _todayTotal = 0; // kept separately for the Dashboard

  DateTime get selectedDate => _selectedDate;
  List<FoodEntry> get entries => List.unmodifiable(_entries);
  List<FoodItem> get searchResults => List.unmodifiable(_searchResults);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get todayTotal => _todayTotal;

  int get totalCalories => _entries.fold(0, (sum, e) => sum + e.calories);

  List<FoodEntry> entriesFor(Meal meal) => _entries.where((e) => e.meal == meal).toList();

  int caloriesFor(Meal meal) => entriesFor(meal).fold(0, (sum, e) => sum + e.calories);

  Future<void> loadEntries() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _entries = await _repository.getEntriesForDate(AppDateUtils.toDbString(_selectedDate));
      await _refreshTodayTotal();
    } catch (e) {
      debugPrint('loadEntries error: $e');
      _errorMessage = 'Could not load your food diary.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshTodayTotal() async {
    final today = AppDateUtils.toDbString(AppDateUtils.today());
    final totals = await _repository.dailyTotalsBetween(today, today);
    _todayTotal = totals[today] ?? 0;
  }

  void changeDay(int direction) {
    final next = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day + direction);
    if (next.isAfter(AppDateUtils.today())) return; // no future days
    _selectedDate = next;
    loadEntries();
  }

  void setDate(DateTime date) {
    _selectedDate = AppDateUtils.dateOnly(date);
    loadEntries();
  }

  Future<void> search(String query) async {
    try {
      _searchResults = await _repository.searchFoods(query);
    } catch (e) {
      debugPrint('search error: $e');
      _searchResults = [];
    }
    notifyListeners();
  }

  /// Calculates calories and saves the entry. Returns an error or null.
  Future<String?> addFood({
    required String name,
    required String portion,
    required int caloriesPerPortion,
    required double servings,
    required Meal meal,
  }) async {
    if (servings <= 0) return 'Servings must be more than 0';
    try {
      await _repository.insertEntry(FoodEntry(
        date: AppDateUtils.toDbString(_selectedDate),
        meal: meal,
        foodName: name,
        portion: portion,
        servings: servings,
        calories: (caloriesPerPortion * servings).round(),
      ));
      await loadEntries();
      return null;
    } catch (e) {
      debugPrint('addFood error: $e');
      return 'Could not add this food.';
    }
  }

  Future<void> deleteEntry(FoodEntry entry) async {
    if (entry.id == null) return;
    _entries.removeWhere((e) => e.id == entry.id);
    notifyListeners();
    try {
      await _repository.deleteEntry(entry.id!);
      await _refreshTodayTotal();
      notifyListeners();
    } catch (e) {
      debugPrint('deleteEntry error: $e');
      await loadEntries();
    }
  }

  Future<void> restoreEntry(FoodEntry entry) async {
    await _repository.insertEntry(entry);
    await loadEntries();
  }
}
