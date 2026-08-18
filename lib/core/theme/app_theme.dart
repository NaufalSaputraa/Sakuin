import 'package:flutter/material.dart';
import 'color_schemes.dart';
import 'typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final scheme = SakuinColors.lightScheme;
    final typography = SakuinTypography.textTheme(
      SakuinColors.lightOnBackground,
      SakuinColors.lightMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: SakuinColors.lightBackground,
      textTheme: typography,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: typography.headlineSmall,
        iconTheme: const IconThemeData(color: SakuinColors.lightOnBackground),
      ),
      cardTheme: CardThemeData(
        color: SakuinColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SakuinColors.lightSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: SakuinColors.lightSurface,
        selectedColor: SakuinColors.lightPrimaryContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: typography.labelMedium,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: SakuinColors.lightPrimary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: CircleBorder(),
      ),
    );
  }

  static ThemeData get darkTheme {
    final scheme = SakuinColors.darkScheme;
    final typography = SakuinTypography.textTheme(
      SakuinColors.darkOnBackground,
      SakuinColors.darkMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: SakuinColors.darkBackground,
      textTheme: typography,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: typography.headlineSmall,
        iconTheme: const IconThemeData(color: SakuinColors.darkOnBackground),
      ),
      cardTheme: CardThemeData(
        color: SakuinColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SakuinColors.darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: SakuinColors.darkSurface,
        selectedColor: SakuinColors.darkPrimaryContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: typography.labelMedium,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: SakuinColors.darkPrimary,
        foregroundColor: Colors.black,
        elevation: 3,
        shape: CircleBorder(),
      ),
    );
  }
}
