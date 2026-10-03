import 'package:flutter/material.dart';
import '../core/theme/migo_colors.dart';

/// Urgent flash deal card. Red accent, countdown, big savings.
class FlashDealCard extends StatelessWidget {
  const FlashDealCard({
    super.key,
    required this.businessName,
    required this.title,
    required this.originalPrice,
    required this.offerPrice,
    required this.currency,
    required this.timeLeft,
    this.onTap,
  });

  final String businessName;
  final String title;
  final double originalPrice;
  final double offerPrice;
  final String currency;
  final String timeLeft;
  final VoidCallback? onTap;

  double get _savings => originalPrice - offerPrice;
  int get _percentOff =>
      originalPrice > 0 ? (((originalPrice - offerPrice) / originalPrice) * 100).round() : 0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: MigoColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MigoColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top strip with FLASH badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                color: MigoColors.error,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.flash_on,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'FLASH',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeLeft,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    businessName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      color: MigoColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: MigoColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$currency ${originalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          color: MigoColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$currency ${offerPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: MigoColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: MigoColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$_percentOff% OFF',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: MigoColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Save $currency ${_savings.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: MigoColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}