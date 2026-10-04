import 'package:flutter/material.dart';
import '../core/theme/migo_colors.dart';
import '../core/theme/migo_gradients.dart';
import '../core/theme/migo_shadows.dart';
import '../models/offer_model.dart';

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

  LinearGradient _placeholderGradient() {
    final c = offer.category.toLowerCase();
    if (c.contains('food')) {
      return const LinearGradient(
        colors: [Color(0xFFFFE0B2), Color(0xFFFFB74D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (c.contains('beauty')) {
      return const LinearGradient(
        colors: [Color(0xFFF8BBD0), Color(0xFFE91E63)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (c.contains('auto')) {
      return const LinearGradient(
        colors: [Color(0xFFB0BEC5), Color(0xFF546E7A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (c.contains('fitness')) {
      return const LinearGradient(
        colors: [Color(0xFFA5D6A7), Color(0xFF43A047)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return MigoGradients.heroBlue;
  }

  @override
  Widget build(BuildContext context) {
    final surface = MigoColors.surface(context);
    final textPrimary = MigoColors.textPrimary(context);
    final textSecondary = MigoColors.textSecondary(context);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: MigoShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (offer.imageUrl != null)
                        Image.network(
                          offer.imageUrl!,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: _placeholderGradient(),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.local_offer,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            offer.type.label.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: MigoColors.primary,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: MigoGradients.success,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${offer.percentOff}% OFF',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.businessName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.2,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${offer.currency} ${offer.offerPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: MigoColors.primaryLight,
                              height: 1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '${offer.currency} ${offer.originalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
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
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: MigoColors.success
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'SAVE ${offer.currency} ${offer.savings.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: MigoColors.success,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 13,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${distanceKm.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.verified,
                            size: 13,
                            color: MigoColors.success,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$verifiedPercent%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }
}