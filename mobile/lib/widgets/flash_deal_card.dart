import 'package:flutter/material.dart';
import '../core/localization/locale_provider.dart';
import '../core/theme/migo_colors.dart';
import '../core/theme/migo_gradients.dart';
import '../models/offer_model.dart';
import '../services/firestore_service.dart';

class FlashDealCard extends StatelessWidget {
  const FlashDealCard({super.key, required this.offer, this.onTap});

  final OfferModel offer;
  final VoidCallback? onTap;

  String _timeLeft(bool isAr) {
    final now = DateTime.now();
    final diff = offer.endAt.difference(now);
    if (diff.isNegative) return isAr ? 'منتهي' : 'Expired';
    if (diff.inHours >= 24) return isAr ? '${diff.inDays} ي' : '${diff.inDays}d left';
    if (diff.inHours >= 1) return isAr ? '${diff.inHours} س' : '${diff.inHours}h left';
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
          width: 180, // 🆕 വീതി അൽപ്പം കൂട്ടി
          height: 240, // 🆕 ഉയരം കൃത്യമാക്കി (Overflow വരാതിരിക്കാൻ)
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
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
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // Image Section
                    if (offer.imageUrl != null && offer.imageUrl!.isNotEmpty)
                      Image.network(
                        offer.imageUrl!,
                        height: 80, // 🆕 ഇമേജ് ഉയരം കൃത്യമാക്കി
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 24)),
                        ),
                      ),

                    // Content Section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0), // 🆕 പാഡിംഗ് കൃത്യമാക്കി
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
                                const SizedBox(height: 4),
                                Text(
                                  offer.title,
                                  maxLines: 2, // 🆕 2 വരികൾ വരെ അനുവദിച്ചു
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary, height: 1.1),
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
                                        padding: const EdgeInsets.only(bottom: 2),
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
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                      child: Text(
                                        '${offer.percentOff}% ${isAr ? 'خصم' : 'OFF'}',
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.red),
                                      ),
                                    ),
                                    FutureBuilder<({double average, int count})>(
                                      future: FirestoreService.instance.getBusinessRating(offer.businessId),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) return const SizedBox.shrink();
                                        final rating = snapshot.data!.average;
                                        final count = snapshot.data!.count;
                                        if (count == 0) {
                                          return Row(
                                            children: [
                                              Icon(Icons.star_border, size: 11, color: textSecondary),
                                              const SizedBox(width: 2),
                                              Text(isAr ? 'جديد' : 'New', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textSecondary)),
                                            ],
                                          );
                                        }
                                        return Row(
                                          children: [
                                            const Icon(Icons.star, size: 11, color: Colors.amber),
                                            const SizedBox(width: 2),
                                            Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87)),
                                            Text(' ($count)', style: TextStyle(fontSize: 9, color: textSecondary)),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
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