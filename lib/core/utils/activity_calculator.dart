import '../../features/settings/models/user_settings.dart';

/// Estimates distance and calories burned from a step count.
///
/// These are standard approximations, not medical measurements:
///  - Stride length is about 41.5% of height for men and 41.3% for women.
///  - Walking burns roughly 0.53 kcal per kg of body weight per km.
class ActivityCalculator {
  ActivityCalculator._();

  static const double kcalPerKgPerKm = 0.53;

  /// Average stride (one step) in centimetres.
  static double strideCm(int heightCm, Gender gender) {
    switch (gender) {
      case Gender.male:
        return heightCm * 0.415;
      case Gender.female:
        return heightCm * 0.413;
      case Gender.other:
        return heightCm * 0.414;
    }
  }

  static double distanceKm(int steps, int heightCm, Gender gender) =>
      steps * strideCm(heightCm, gender) / 100000;

  /// Calories burned by walking [steps] steps, rounded to whole kcal.
  static int caloriesFromSteps({
    required int steps,
    required int heightCm,
    required double weightKg,
    required Gender gender,
  }) {
    if (steps <= 0) return 0;
    final km = distanceKm(steps, heightCm, gender);
    return (km * weightKg * kcalPerKgPerKm).round();
  }
}
