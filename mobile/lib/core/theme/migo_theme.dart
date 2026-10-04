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
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: MigoColors.textPrimaryLight,
            letterSpacing: -0.3,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            color: MigoColors.textPrimaryLight,
          ),
          headlineLarge: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: MigoColors.textPrimaryLight,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: MigoColors.textPrimaryLight,
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: MigoColors.textPrimaryLight,
          ),
          titleLarge: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: MigoColors.textPrimaryLight,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: MigoColors.textPrimaryLight,
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            color: MigoColors.textPrimaryLight,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: MigoColors.textPrimaryLight,
            height: 1.5,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: MigoColors.textSecondaryLight,
            height: 1.4,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: MigoColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            minimumSize: const Size(0, 52),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: MigoColors.primary,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            minimumSize: const Size(0, 52),
            side: BorderSide(
              color: MigoColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: MigoColors.primary,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: MigoColors.surfaceLight,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: MigoColors.surfaceLight,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintStyle: const TextStyle(
            color: MigoColors.textSecondaryLight,
            fontSize: 14,
          ),
          labelStyle: const TextStyle(
            color: MigoColors.textSecondaryLight,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: MigoColors.primary,
              width: 1.6,
            ),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: MigoColors.dividerLight,
          thickness: 1,
          space: 1,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: MigoColors.surfaceLight,
          side: const BorderSide(color: MigoColors.dividerLight),
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: MigoColors.textPrimaryLight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: MigoColors.surfaceLight,
          indicatorColor: MigoColors.accent.withValues(alpha: 0.18),
          elevation: 0,
          height: 68,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: MigoColors.primary,
              );
            }
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: MigoColors.textSecondaryLight,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: MigoColors.primary,
                size: 24,
              );
            }
            return const IconThemeData(
              color: MigoColors.textSecondaryLight,
              size: 24,
            );
          }),
        ),
      );

  // ---------- DARK THEME ----------
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
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: MigoColors.textPrimaryDark,
            letterSpacing: -0.3,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            color: MigoColors.textPrimaryDark,
          ),
          headlineLarge: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: MigoColors.textPrimaryDark,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: MigoColors.textPrimaryDark,
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: MigoColors.textPrimaryDark,
          ),
          titleLarge: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: MigoColors.textPrimaryDark,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: MigoColors.textPrimaryDark,
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            color: MigoColors.textPrimaryDark,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: MigoColors.textPrimaryDark,
            height: 1.5,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: MigoColors.textSecondaryDark,
            height: 1.4,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: MigoColors.accent,
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            minimumSize: const Size(0, 52),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: MigoColors.accent,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            minimumSize: const Size(0, 52),
            side: BorderSide(
              color: MigoColors.accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: MigoColors.accent,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: MigoColors.surfaceDark,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: MigoColors.surfaceDark,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintStyle: const TextStyle(
            color: MigoColors.textSecondaryDark,
            fontSize: 14,
          ),
          labelStyle: const TextStyle(
            color: MigoColors.textSecondaryDark,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: MigoColors.accent,
              width: 1.6,
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: MigoColors.dividerDark,
          thickness: 1,
          space: 1,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: MigoColors.surfaceDark,
          side: const BorderSide(color: MigoColors.dividerDark),
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: MigoColors.textPrimaryDark,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: MigoColors.surfaceDark,
          indicatorColor: MigoColors.accent.withValues(alpha: 0.22),
          elevation: 0,
          height: 68,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: MigoColors.accent,
              );
            }
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: MigoColors.textSecondaryDark,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: MigoColors.accent,
                size: 24,
              );
            }
            return const IconThemeData(
              color: MigoColors.textSecondaryDark,
              size: 24,
            );
          }),
        ),
      );
}