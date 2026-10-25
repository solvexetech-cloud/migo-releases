import 'package:flutter/material.dart';
import '../core/localization/locale_provider.dart';
import '../core/theme/migo_colors.dart';
import '../core/theme/migo_gradients.dart';
import '../core/theme/migo_shadows.dart';
import '../models/offer_model.dart';

class FlashDealCard extends StatelessWidget {
  const FlashDealCard({super.key, required this.offer, this.onTap});

  final OfferModel offer;
  final VoidCallback? onTap;

  String _timeLeft(bool isAr) {
    final now = DateTime.now();
    final diff = offer.endAt.difference(now);
    if (diff.isNegative) return isAr ? 'منتهي' : 'Expired';
    if (diff.inHours >= 24) return isAr ? '${diff.inDays} ي' : '${diff.inDays}d left';
    if (diff.inHours >= 1) return isAr ? '${diff.inHours} س' : '${diff.inHours}h ${diff.inMinutes % 60}m left';
    return isAr ? '${diff.inMinutes} د' : '${diff.inMinutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final surface = MigoColors.surface(context);
    final textPrimary = MigoColors.textPrimary(context);
    final textSecondary = MigoColors.textSecondary(context);

    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Container(
          width: 200,
          height: 230,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: MigoShadows.redGlow,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: const BoxDecoration(gradient: MigoGradients.flash),
                      child: Row(
                        children: [
                          const Icon(Icons.flash_on, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            isAr ? 'فلاش' : 'FLASH',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          const Spacer(),
                          Text(
                            _timeLeft(isAr),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    
                    // Image Section
                    if (offer.imageUrl != null && offer.imageUrl!.isNotEmpty)
                      Image.network(
                        offer.imageUrl!,
                        height: 75,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 75,
                          color: Colors.grey.shade200,
                          child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 30)),
                        ),
                      ),

                    // Content Section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offer.businessName.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  offer.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textPrimary, height: 1.1),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${offer.currency} ${offer.offerPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: MigoColors.primaryLight, height: 1),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 1),
                                        child: Text(
                                          '${offer.currency} ${offer.originalPrice.toStringAsFixed(0)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 9, decoration: TextDecoration.lineThrough, color: textSecondary),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(gradient: MigoGradients.flash, borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                    '${offer.percentOff}% ${isAr ? 'خصم' : 'OFF'}',
                                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}