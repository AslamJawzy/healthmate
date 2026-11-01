/// MODEL: one food from the built-in Sri Lankan food list (`foods` table).
class FoodItem {
  final int? id;
  final String name;
  final String category;
  final String portion; // e.g. "1 plate", "10 pieces"
  final int calories; // kcal for ONE portion

  const FoodItem({
    this.id,
    required this.name,
    required this.category,
    required this.portion,
    required this.calories,
  });

  factory FoodItem.fromMap(Map<String, dynamic> map) => FoodItem(
        id: map['id'] as int?,
        name: map['name'] as String,
        category: map['category'] as String,
        portion: map['portion'] as String,
        calories: map['calories'] as int,
      );
}
