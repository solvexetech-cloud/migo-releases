import 'package:flutter/material.dart';

import 'migo_theme.dart';

/// PHASE I — Gradient helpers
class MigoGradients {
  MigoGradients._();

  static LinearGradient get softBlue => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          MigoColors.primary.withValues(alpha: 0.08),
          MigoColors.primary.withValues(alpha: 0.02),
        ],
      );

  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [MigoColors.primary, MigoColors.primaryDark],
      );

  static LinearGradient get goldGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [MigoColors.accent, MigoColors.accentDark],
      );
}