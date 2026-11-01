/// MODEL LAYER
/// A HealthRecord represents ONE row in the `health_records` table.
/// It knows how to convert itself to a Map (to save into SQLite)
/// and how to build itself from a Map (when reading from SQLite).
class HealthRecord {
  final int? id; // Primary key. Null until the record is saved.
  final String date; // Stored as text in the format yyyy-MM-dd
  final int steps; // Steps walked
  final int calories; // Calories burned (kcal)
  final int water; // Water intake (ml)

  const HealthRecord({
    this.id,
    required this.date,
    required this.steps,
    required this.calories,
    required this.water,
  });

  /// Converts the text date back into a DateTime object.
  DateTime get dateTime => DateTime.parse(date);

  /// Builds a HealthRecord from a database row.
  factory HealthRecord.fromMap(Map<String, dynamic> map) {
    return HealthRecord(
      id: map['id'] as int?,
      date: map['date'] as String,
      steps: map['steps'] as int,
      calories: map['calories'] as int,
      water: map['water'] as int,
    );
  }

  /// Converts this record into a Map so sqflite can save it.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date': date,
      'steps': steps,
      'calories': calories,
      'water': water,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  /// Creates a copy with some values changed (used when editing).
  HealthRecord copyWith({
    int? id,
    String? date,
    int? steps,
    int? calories,
    int? water,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      calories: calories ?? this.calories,
      water: water ?? this.water,
    );
  }

  @override
  String toString() =>
      'HealthRecord(id: $id, date: $date, steps: $steps, calories: $calories, water: $water)';
}
