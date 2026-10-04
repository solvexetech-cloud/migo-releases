import 'package:flutter/material.dart';

/// MIGO Brand Colors
/// Light: warm cream + deep blue + gold
/// Dark: deep navy + soft surfaces + gold accents
class MigoColors {
  MigoColors._();

  // ---------- Brand ----------
  static const Color primary = Color(0xFF0B2B5B);
  static const Color primaryLight = Color(0xFF1E4B8F);
  static const Color primaryDark = Color(0xFF061B3D);

  static const Color accent = Color(0xFFD4A13A);
  static const Color accentLight = Color(0xFFF0C566);
  static const Color accentDark = Color(0xFFA67920);

  // ---------- Status ----------
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE8A020);
  static const Color error = Color(0xFFD64545);
  static const Color info = Color(0xFF2A7FBF);

  // ---------- LIGHT THEME ----------
  static const Color backgroundLight = Color(0xFFF6F3EE);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF0EDE7);
  static const Color textPrimaryLight = Color(0xFF111418);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color dividerLight = Color(0xFFECE7DE);

  // ---------- DARK THEME ----------
  // Deep Navy (not pure black) — warm, premium
  static const Color backgroundDark = Color(0xFF0A1628);
  static const Color surfaceDark = Color(0xFF13243E);
  static const Color surfaceVariantDark = Color(0xFF1B2F4F);
  static const Color textPrimaryDark = Color(0xFFF5F7FA);
  static const Color textSecondaryDark = Color(0xFF9BB0CC);
  static const Color dividerDark = Color(0xFF233A5C);

  // ---------- Helpers (Theme-aware) ----------
  static Color bg(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? backgroundDark
          : backgroundLight;

  static Color surface(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? surfaceDark
          : surfaceLight;

  static Color surfaceVariant(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? surfaceVariantDark
          : surfaceVariantLight;

  static Color textPrimary(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? textPrimaryDark
          : textPrimaryLight;

  static Color textSecondary(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? textSecondaryDark
          : textSecondaryLight;

  static Color divider(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? dividerDark
          : dividerLight;
}