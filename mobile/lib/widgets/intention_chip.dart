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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? MigoGradients.primaryButton : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? MigoColors.primary
                  : const Color(0xFFECE7DE),
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: MigoColors.primary.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : MigoColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color:
                      selected ? Colors.white : MigoColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}