import 'package:flutter/material.dart';
import '../core/theme/migo_colors.dart';

/// Small pill-style chip used for MIGO intention-based discovery.
/// Example intentions: Eat, Coffee, Family, Save Money, Celebrate...
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
    final bg = selected ? MigoColors.primary : MigoColors.surfaceLight;
    final fg = selected ? Colors.white : MigoColors.textPrimaryLight;
    final border = selected
        ? MigoColors.primary
        : MigoColors.dividerLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}