import 'package:flutter/material.dart';
import '../core/theme/migo_gradients.dart';
import '../core/theme/migo_shadows.dart';

/// Gold gradient button — for premium actions (Pick For Me, Claim).
class MigoGoldButton extends StatelessWidget {
  const MigoGoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: disabled ? null : MigoGradients.gold,
        color: disabled ? const Color(0xFFE8DCB8) : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: disabled ? null : MigoShadows.goldGlow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: disabled ? null : onPressed,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.black, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}