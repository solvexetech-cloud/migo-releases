import 'package:flutter/material.dart';
import '../core/theme/migo_colors.dart';
import '../core/theme/migo_shadows.dart';

/// Standard MIGO card with soft shadow and rounded corners.
class MigoCard extends StatelessWidget {
  const MigoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderRadius = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final c = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? MigoColors.surfaceLight,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: MigoShadows.soft,
      ),
      child: child,
    );

    if (onTap == null) return c;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: c,
      ),
    );
  }
}