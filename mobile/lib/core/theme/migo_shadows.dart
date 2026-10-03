import 'package:flutter/material.dart';
import 'migo_colors.dart';

/// Consistent elevation shadows across MIGO.
class MigoShadows {
  MigoShadows._();

  /// Subtle — default cards.
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// Medium — elevated cards, wallet card.
  static List<BoxShadow> get medium => [
        BoxShadow(
          color: MigoColors.primary.withValues(alpha: 0.15),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// Strong — hero card, primary CTA.
  static List<BoxShadow> get strong => [
        BoxShadow(
          color: MigoColors.primary.withValues(alpha: 0.28),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];

  /// Gold glow — accent buttons.
  static List<BoxShadow> get goldGlow => [
        BoxShadow(
          color: MigoColors.accent.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// Red glow — flash deals.
  static List<BoxShadow> get redGlow => [
        BoxShadow(
          color: MigoColors.error.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}