import 'package:flutter/material.dart';
import '../core/theme/migo_colors.dart';
import '../core/theme/migo_gradients.dart';
import '../core/theme/migo_shadows.dart';
import '../models/offer_model.dart';

/// Urgent flash deal card with red gradient top strip.
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
    final surface = MigoColors.surface(context);
    final textPrimary = MigoColors.textPrimary(context);
    final textSecondary = MigoColors.textSecondary(context);

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: MigoShadows.redGlow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Red gradient header strip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    gradient: MigoGradients.flash,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.flash_on,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'FLASH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _timeLeft(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
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
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w800,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        offer.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${offer.currency} ${offer.offerPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: MigoColors.primaryLight,
                              height: 1,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '${offer.currency} ${offer.originalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11,
                                decoration:
                                    TextDecoration.lineThrough,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: MigoGradients.flash,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${offer.percentOff}% OFF',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
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