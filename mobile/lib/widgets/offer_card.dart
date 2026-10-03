import 'package:flutter/material.dart';
import '../core/theme/migo_colors.dart';
import '../models/offer_model.dart';

/// Decision-focused offer card built from an OfferModel.
class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.offer,
    this.distanceKm = 1.5,
    this.verifiedPercent = 92,
    this.onTap,
  });

  final OfferModel offer;
  final double distanceKm;
  final int verifiedPercent;
  final VoidCallback? onTap;

  double get _savings => offer.savings;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: MigoColors.primary.withValues(alpha: 0.08),
                child: offer.imageUrl == null
                    ? const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: MigoColors.primary,
                        ),
                      )
                    : Image.network(offer.imageUrl!, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.businessName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MigoColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${offer.currency} ${offer.originalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          decoration: TextDecoration.lineThrough,
                          color: MigoColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${offer.currency} ${offer.offerPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: MigoColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: MigoColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'SAVE ${offer.currency} ${_savings.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MigoColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: MigoColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 12,
                          color: MigoColors.textSecondaryLight,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: MigoColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$verifiedPercent%',
                        style: const TextStyle(
                          fontSize: 12,
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