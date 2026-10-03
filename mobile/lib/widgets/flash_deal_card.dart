import 'package:flutter/material.dart';
import '../core/theme/migo_colors.dart';
import '../models/offer_model.dart';

/// Urgent flash deal card. Built from an OfferModel.
class FlashDealCard extends StatelessWidget {
  const FlashDealCard({super.key, required this.offer, this.onTap});

  final OfferModel offer;
  final VoidCallback? onTap;

  String _timeLeft() {
    final now = DateTime.now();
    final diff = offer.endAt.difference(now);
    if (diff.isNegative) return 'Expired';
    if (diff.inHours >= 24) return '${diff.inDays}d left';
    if (diff.inHours >= 1) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m left';
    }
    return '${diff.inMinutes}m left';
  }

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
          border: Border.all(
            color: MigoColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
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
                    _timeLeft(),
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
                    offer.businessName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      color: MigoColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.title,
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
                        '${offer.currency} ${offer.originalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          color: MigoColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${offer.currency} ${offer.offerPrice.toStringAsFixed(0)}',
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
                          '${offer.percentOff}% OFF',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: MigoColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Save ${offer.currency} ${offer.savings.toStringAsFixed(0)}',
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