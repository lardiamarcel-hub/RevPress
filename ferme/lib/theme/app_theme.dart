import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color vertFerme = Color(0xFF2E7D32);
  static const Color orDepense = Color(0xFFC62828);
  static const Color orRecette = Color(0xFF2E7D32);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: vertFerme,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF6F8F4),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      cardTheme: const CardTheme(
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 4),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: vertFerme,
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }
}
