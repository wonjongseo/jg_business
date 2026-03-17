import 'package:flutter/material.dart';
import 'package:jg_business/shared/theme/app_tokens.dart';

abstract final class AppTheme {
  static const _seed = AppColors.accent;
  static const _surfaceTint = Color(0xFFF5F1E8);
  static const _ink = AppColors.ink;

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _surfaceTint,
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 78,
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.94),
        indicatorColor: AppColors.accentSoft,
        labelTextStyle: MaterialStatePropertyAll(
          TextStyle(
            color: _ink.withOpacity(0.78),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white.withOpacity(0.9),
        indicatorColor: AppColors.accentSoft,
        selectedIconTheme: const IconThemeData(color: _ink),
        unselectedIconTheme: IconThemeData(color: _ink.withOpacity(0.54)),
        selectedLabelTextStyle: const TextStyle(
          color: _ink,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(color: _ink.withOpacity(0.7)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide.none,
        backgroundColor: AppColors.outlineSoft,
        selectedColor: AppColors.accentSoft,
        labelStyle: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: _ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        titleLarge: TextStyle(
          color: _ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        titleMedium: TextStyle(color: _ink, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: _ink, height: 1.4),
        bodyMedium: TextStyle(color: _ink, height: 1.35),
      ),
    );
  }
}
