/// Form validation rules. Each function returns an error message,
/// or null when the value is valid (this is what Flutter forms expect).
class Validators {
  Validators._();

  static const int maxSteps = 100000;
  static const int maxCalories = 10000;
  static const int maxWater = 10000;

  static String? wholeNumber(
    String? value, {
    required String fieldName,
    required int max,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    final number = int.tryParse(value.trim());
    if (number == null) {
      return '$fieldName must be a whole number';
    }
    if (number < 0) {
      return '$fieldName cannot be negative';
    }
    if (number > max) {
      return '$fieldName looks too high (max $max)';
    }
    return null;
  }

  static String? steps(String? v) =>
      wholeNumber(v, fieldName: 'Steps', max: maxSteps);

  static String? calories(String? v) =>
      wholeNumber(v, fieldName: 'Calories', max: maxCalories);

  static String? water(String? v) =>
      wholeNumber(v, fieldName: 'Water intake', max: maxWater);

  /// Goals must be within a sensible range (a goal of 0 makes no sense).
  static String? goal(
    String? value, {
    required String fieldName,
    required int min,
    required int max,
  }) {
    final basic = wholeNumber(value, fieldName: fieldName, max: max);
    if (basic != null) return basic;
    if (int.parse(value!.trim()) < min) return '$fieldName should be at least $min';
    return null;
  }

  /// A record cannot be added for a future date.
  static String? notFutureDate(DateTime? date, DateTime today) {
    if (date == null) return 'Please choose a date';
    if (date.isAfter(today)) return 'Date cannot be in the future';
    return null;
  }
}
