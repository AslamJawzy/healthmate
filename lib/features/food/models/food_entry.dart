/// Meals of the day, in display order.
enum Meal { breakfast, lunch, dinner, snack }

extension MealInfo on Meal {
  String get label {
    switch (this) {
      case Meal.breakfast:
        return 'Breakfast';
      case Meal.lunch:
        return 'Lunch';
      case Meal.dinner:
        return 'Dinner';
      case Meal.snack:
        return 'Snacks';
    }
  }

  String get emoji {
    switch (this) {
      case Meal.breakfast:
        return '🌅';
      case Meal.lunch:
        return '🍛';
      case Meal.dinner:
        return '🌙';
      case Meal.snack:
        return '🍪';
    }
  }

  /// Suggests a meal from the time of day when adding food.
  static Meal fromTime(DateTime t) {
    if (t.hour < 11) return Meal.breakfast;
    if (t.hour < 16) return Meal.lunch;
    if (t.hour < 18) return Meal.snack;
    return Meal.dinner;
  }
}

/// MODEL: one food the user ate (`food_entries` table).
class FoodEntry {
  final int? id;
  final String date; // yyyy-MM-dd
  final Meal meal;
  final String foodName;
  final String portion;
  final double servings; // 0.5, 1, 1.5, 2 ...
  final int calories; // total kcal = portion kcal x servings

  const FoodEntry({
    this.id,
    required this.date,
    required this.meal,
    required this.foodName,
    required this.portion,
    required this.servings,
    required this.calories,
  });

  factory FoodEntry.fromMap(Map<String, dynamic> map) => FoodEntry(
        id: map['id'] as int?,
        date: map['date'] as String,
        meal: Meal.values.byName(map['meal'] as String),
        foodName: map['food_name'] as String,
        portion: map['portion'] as String,
        servings: (map['servings'] as num).toDouble(),
        calories: map['calories'] as int,
      );

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date': date,
      'meal': meal.name,
      'food_name': foodName,
      'portion': portion,
      'servings': servings,
      'calories': calories,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  /// "1.5 x 1 plate" or "1 plate"
  String get servingText {
    if (servings == 1) return portion;
    final s = servings == servings.roundToDouble() ? servings.toInt().toString() : servings.toString();
    return '$s x $portion';
  }
}
