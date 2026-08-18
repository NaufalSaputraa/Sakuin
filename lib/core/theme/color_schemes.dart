import 'package:flutter/material.dart';

class SakuinColors {
  // Light Palette (PennywiseAI warm cream / ivory)
  static const Color lightBackground = Color(0xFFFFF8F0);
  static const Color lightSurface = Color(0xFFFFF1E6);
  static const Color lightPrimary = Color(0xFF6B5CE7);
  static const Color lightPrimaryContainer = Color(0xFFEDE8FF);
  static const Color lightSecondary = Color(0xFF3B82C4);
  static const Color lightAccent = Color(0xFFE74C8B);
  static const Color lightOnBackground = Color(0xFF1A1A2E);
  static const Color lightOnSurface = Color(0xFF4A4A6A);
  static const Color lightMuted = Color(0xFF9B9BB5);
  static const Color lightIncome = Color(0xFF2ECC71);
  static const Color lightExpense = Color(0xFFE74C3C);

  // Dark Palette (PennywiseAI deep navy / slate)
  static const Color darkBackground = Color(0xFF0D0D1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkPrimary = Color(0xFF8B7CF7);
  static const Color darkPrimaryContainer = Color(0xFF2D2650);
  static const Color darkSecondary = Color(0xFF5BA3E6);
  static const Color darkAccent = Color(0xFFFF5388);
  static const Color darkOnBackground = Color(0xFFE8E8F0);
  static const Color darkOnSurface = Color(0xFFB0B0CC);
  static const Color darkMuted = Color(0xFF6F6F90);
  static const Color darkIncome = Color(0xFF4ADE80);
  static const Color darkExpense = Color(0xFFF87171);

  static ColorScheme get lightScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: lightPrimary,
        onPrimary: Colors.white,
        primaryContainer: lightPrimaryContainer,
        onPrimaryContainer: lightPrimary,
        secondary: lightSecondary,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFD8ECFD),
        onSecondaryContainer: lightSecondary,
        surface: lightSurface,
        onSurface: lightOnSurface,
        error: lightExpense,
        onError: Colors.white,
        outline: Color(0xFFE2D9CF),
        outlineVariant: Color(0xFFF0E5DA),
      );

  static ColorScheme get darkScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: Colors.black,
        primaryContainer: darkPrimaryContainer,
        onPrimaryContainer: darkPrimary,
        secondary: darkSecondary,
        onSecondary: Colors.black,
        secondaryContainer: Color(0xFF19324C),
        onSecondaryContainer: darkSecondary,
        surface: darkSurface,
        onSurface: darkOnSurface,
        error: darkExpense,
        onError: Colors.black,
        outline: Color(0xFF2D2D44),
        outlineVariant: Color(0xFF232338),
      );
}
