import 'package:flutter/material.dart';
import 'color_schemes.dart';
import 'typography.dart';

class AppTheme {
  /// Build a [ThemeData] from an explicit [ColorScheme].
  ///
  /// If [scheme] is `null` the legacy static palette is used (backward
  /// compatible with the current `main.dart` until it switches over).
  static ThemeData light({ColorScheme? scheme}) {
    final s = scheme ?? SakuinColors.lightScheme;
    final typography = SakuinTypography.textTheme(
      SakuinColors.lightOnBackground,
      SakuinColors.lightMuted,
    );

    return _build(
      scheme: s,
      typography: typography,
      scaffoldBg: SakuinColors.lightBackground,
      brightness: Brightness.light,
    );
  }

  static ThemeData dark({ColorScheme? scheme}) {
    final s = scheme ?? SakuinColors.darkScheme;
    final typography = SakuinTypography.textTheme(
      SakuinColors.darkOnBackground,
      SakuinColors.darkMuted,
    );

    return _build(
      scheme: s,
      typography: typography,
      scaffoldBg: SakuinColors.darkBackground,
      brightness: Brightness.dark,
    );
  }

  // ── Keep the old getters for backward compat ──────────────────────
  static ThemeData get lightTheme => light();
  static ThemeData get darkTheme => dark();

  // ── Shared builder ──────────────────────────────────────────────

  static ThemeData _build({
    required ColorScheme scheme,
    required TextTheme typography,
    required Color scaffoldBg,
    required Brightness brightness,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: typography,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: typography.headlineSmall,
        iconTheme: IconThemeData(
          color: scheme.brightness == Brightness.light
              ? SakuinColors.lightOnBackground
              : SakuinColors.darkOnBackground,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: typography.labelMedium,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        shape: const CircleBorder(),
      ),
    );
  }
}
