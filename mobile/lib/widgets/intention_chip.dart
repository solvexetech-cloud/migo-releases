import 'package:flutter/material.dart';
import '../core/theme/migo_colors.dart';
import '../core/theme/migo_gradients.dart';

/// Intention chip — pill style with gradient when selected.
class IntentionChip extends StatelessWidget {
  const IntentionChip({
    super.key,
    required this.label,
    required this.icon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark
        ? MigoColors.surfaceVariantDark
        : Colors.white;
    final unselectedBorder = isDark
        ? MigoColors.dividerDark
        : const Color(0xFFECE7DE);
    final unselectedFg =
        isDark ? MigoColors.textPrimaryDark : MigoColors.textPrimaryLight;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            gradient: selected ? MigoGradients.primaryButton : null,
            color: selected ? null : unselectedBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? MigoColors.primary : unselectedBorder,
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color:
                          MigoColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : (isDark ? MigoColors.accent : MigoColors.primary),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : unselectedFg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}