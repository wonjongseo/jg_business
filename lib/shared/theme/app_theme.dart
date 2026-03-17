/// 앱 전역 Material 테마를 정의한다.
import 'package:flutter/material.dart';
import 'package:jg_business/shared/theme/app_tokens.dart';

abstract final class AppTheme {
  static const _seed = AppColors.accent;
  static const _surfaceTint = Color(0xFFF5F1E8);
  static const _ink = AppColors.ink;
  static const _darkSurface = Color(0xFF101715);
  static const _darkCard = Color(0xFF17211E);
  static const _darkInk = Color(0xFFF3F6F4);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      surface: AppColors.surface,
    ).copyWith(
      primary: AppColors.accent,
      secondary: AppColors.secondary,
      tertiary: AppColors.secondary,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.accent,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _surfaceTint,
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
        ),
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

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      surface: _darkSurface,
    ).copyWith(
      primary: AppColors.accent,
      secondary: AppColors.secondary,
      tertiary: AppColors.secondary,
      surface: _darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.accent,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0C1210),
      cardTheme: const CardThemeData(
        color: _darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _darkInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 78,
        elevation: 0,
        backgroundColor: const Color(0xFF18211E),
        indicatorColor: AppColors.accent.withOpacity(0.28),
        labelTextStyle: const MaterialStatePropertyAll(
          TextStyle(
            color: _darkInk,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFF18211E),
        indicatorColor: AppColors.accent.withOpacity(0.28),
        selectedIconTheme: const IconThemeData(color: _darkInk),
        unselectedIconTheme: const IconThemeData(color: Color(0xFF98A49F)),
        selectedLabelTextStyle: const TextStyle(
          color: _darkInk,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: const TextStyle(color: Color(0xFF98A49F)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide.none,
        backgroundColor: const Color(0xFF22302B),
        selectedColor: AppColors.accent.withOpacity(0.28),
        labelStyle: const TextStyle(color: _darkInk, fontWeight: FontWeight.w600),
      ),
      dividerColor: const Color(0xFF2A3833),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A2521),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF2A3833)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF2A3833)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
        ),
        labelStyle: const TextStyle(color: Color(0xFFC6D0CB)),
        hintStyle: const TextStyle(color: Color(0xFF98A49F)),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: _darkInk,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        headlineSmall: TextStyle(
          color: _darkInk,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          color: _darkInk,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        titleMedium: TextStyle(color: _darkInk, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: _darkInk, height: 1.4),
        bodyMedium: TextStyle(color: _darkInk, height: 1.35),
        bodySmall: TextStyle(color: Color(0xFFC6D0CB)),
      ),
    );
  }
}
