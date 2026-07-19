import 'package:flutter/material.dart';

class AppColors {
  static const paper = Color(0xFFFFFAF3);
  static const rose = Color(0xFFF7DCE5);
  static const lavender = Color(0xFFE8DDF3);
  static const plum = Color(0xFF673A62);
  static const apricot = Color(0xFFF4B889);
  static const ink = Color(0xFF382D36);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.plum,
    brightness: Brightness.light,
    surface: AppColors.paper,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.paper,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w800,
        color: AppColors.plum,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      bodyLarge: TextStyle(fontSize: 17, height: 1.35, color: AppColors.ink),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.82),
      elevation: 2,
      shadowColor: AppColors.plum.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(56, 54),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.75),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
