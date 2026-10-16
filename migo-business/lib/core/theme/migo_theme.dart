import 'package:flutter/material.dart';

/// PHASE I — MIGO Business Theme
/// Corporate blue + Gold accents
class MigoColors {
  MigoColors._();

  // Primary
  static const primary = Color(0xFF0B2B5B);      // Corporate blue
  static const primaryDark = Color(0xFF061B3D);

  // Accent
  static const accent = Color(0xFFF0C566);       // Gold
  static const accentDark = Color(0xFFD4A13A);   // Gold dark

  // Status
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Backgrounds
  static const background = Color(0xFFF6F3EE);   // Cream
  static const surface = Colors.white;

  // Text
  static const textPrimary = Color(0xFF111418);
  static const textSecondary = Color(0xFF6B7280);
  static const divider = Color(0xFFE5E7EB);
}

class MigoTheme {
  MigoTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MigoColors.primary,
          primary: MigoColors.primary,
          secondary: MigoColors.accent,
          surface: MigoColors.surface,
          error: MigoColors.error,
        ),
        scaffoldBackgroundColor: MigoColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: MigoColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: MigoColors.divider),
          ),
          color: MigoColors.surface,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: MigoColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: MigoColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: MigoColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: MigoColors.primary,
              width: 2,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: MigoColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}