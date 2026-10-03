import 'package:flutter/material.dart';
import 'migo_colors.dart';

/// Gradient presets used across MIGO.
/// Centralized so any screen can reuse without inventing new ones.
class MigoGradients {
  MigoGradients._();

  /// Deep Blue hero gradient — headers, wallet card.
  static const LinearGradient heroBlue = LinearGradient(
    colors: [Color(0xFF0B2B5B), Color(0xFF1E4B8F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Darker variant for stronger contrast.
  static const LinearGradient heroBlueDark = LinearGradient(
    colors: [Color(0xFF061B3D), Color(0xFF0B2B5B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gold gradient — accent buttons, sparkles.
  static const LinearGradient gold = LinearGradient(
    colors: [Color(0xFFF0C566), Color(0xFFD4A13A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Green gradient — success, savings.
  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF3DB86E), Color(0xFF2E9E5B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Red gradient — flash deals, urgency.
  static const LinearGradient flash = LinearGradient(
    colors: [Color(0xFFE85D5D), Color(0xFFD64545)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Primary button gradient.
  static const LinearGradient primaryButton = LinearGradient(
    colors: [Color(0xFF1E4B8F), Color(0xFF0B2B5B)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Card overlay gradient（for images — fade to dark at bottom）.
  static const LinearGradient imageOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0x99000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Soft background gradient for empty states.
  static LinearGradient softBlue = LinearGradient(
    colors: [
      MigoColors.primary.withValues(alpha: 0.08),
      MigoColors.primary.withValues(alpha: 0.02),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}