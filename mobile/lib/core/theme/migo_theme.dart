import 'package:flutter/material.dart';
import 'migo_colors.dart';

class MigoTheme {
  MigoTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: MigoColors.backgroundLight,
        colorScheme: const ColorScheme.light(
          primary: MigoColors.primary,
          secondary: MigoColors.accent,
          surface: MigoColors.surfaceLight,
          error: MigoColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: MigoColors.textPrimaryLight,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: MigoColors.backgroundLight,
          foregroundColor: MigoColors.textPrimaryLight,
          elevation: 0,
          centerTitle: false,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontWeight: FontWeight.w700,
            color: MigoColors.textPrimaryLight,
          ),
          headlineMedium: TextStyle(
            fontWeight: FontWeight.w700,
            color: MigoColors.textPrimaryLight,
          ),
          titleLarge: TextStyle(
            fontWeight: FontWeight.w600,
            color: MigoColors.textPrimaryLight,
          ),
          bodyLarge: TextStyle(color: MigoColors.textPrimaryLight),
          bodyMedium: TextStyle(color: MigoColors.textPrimaryLight),
          bodySmall: TextStyle(color: MigoColors.textSecondaryLight),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: MigoColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: MigoColors.surfaceLight,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dividerColor: MigoColors.dividerLight,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: MigoColors.backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: MigoColors.accent,
          secondary: MigoColors.primaryLight,
          surface: MigoColors.surfaceDark,
          error: MigoColors.error,
          onPrimary: Colors.black,
          onSecondary: Colors.white,
          onSurface: MigoColors.textPrimaryDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: MigoColors.backgroundDark,
          foregroundColor: MigoColors.textPrimaryDark,
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: MigoColors.accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: MigoColors.surfaceDark,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dividerColor: MigoColors.dividerDark,
      );
}