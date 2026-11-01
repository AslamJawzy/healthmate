import 'package:flutter/material.dart';

/// One colour per health metric, so users recognise each metric instantly.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF00897B); // Teal: calm, health related
  static const Color steps = Color(0xFF43A047); // Green: activity, movement
  static const Color calories = Color(0xFFE53935); // Red: energy, burning
  static const Color water = Color(0xFF1E88E5); // Blue: water
  static const Color food = Color(0xFFFB8C00); // Orange: food, appetite
  static const Color sleep = Color(0xFF5E35B1); // Indigo: night, rest
  static const Color breathing = Color(0xFF00ACC1); // Cyan: air, calm
}

/// Icons for each metric, used everywhere for consistency.
class AppIcons {
  AppIcons._();

  static const IconData steps = Icons.directions_walk;
  static const IconData calories = Icons.local_fire_department;
  static const IconData water = Icons.water_drop;
}
