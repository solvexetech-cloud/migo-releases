import 'dart:async'; // 🆕 Timer-ന് വേണ്ടി ചേർത്തത്
import 'package:flutter/material.dart';
import '../core/localization/locale_provider.dart';
import '../core/theme/migo_colors.dart';
import '../core/theme/migo_gradients.dart';
import '../core/theme/migo_shadows.dart';
import '../models/offer_model.dart';
import '../services/firestore_service.dart';

// 🆕 StatelessWidget മാറ്റി StatefulWidget ആ ്കി
class OfferCard extends StatefulWidget {
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

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  Timer? _promoTimer; // 🆕 ടൈമർ വേരിയബിൾ

  @override
  void initState() {
    super.initState();
    _startPromoTimer();
  }

  // 🆕 പ്രൊമോഷൻ സമയം കഴിയുമ്പോൾ UI റിഫ്രെഷ് ചെയ്യാനുള്ള ടൈമർ
  void _startPromoTimer() {
    final offer = widget.offer;
    if (offer.isPromoted && offer.promotedUntil != null) {
      final now = DateTime.now();
      if (offer.promotedUntil!.isAfter(now)) {
        final diff = offer.promotedUntil!.difference(now);
        _promoTimer = Timer(diff, () {
          if (mounted) {
            setState(() {}); // സമയം കഴിഞ്ഞാൽ UI അപ്ഡേറ്റ് ചെയ്യുന്നു
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _promoTimer?.cancel(); // 🆕 മെമ്മറി ലീക്ക് ഒഴിവാക്കാൻ
    super.dispose();
  }

  // കാറ്റഗറി അനുസരിച്ച് നിറം നൽകുന്നു
  Color _getCategoryColor() {
    final cat = widget.offer.category.toLowerCase();
    if (cat.contains('food')) return Colors.orange;
    if (cat.contains('beauty')) return Colors.pink;
    if (cat.contains('supermarket')) return Colors.green;
    if (cat.contains('retail') || cat.contains('shopping')) return Colors.purple;
    if (cat.contains('flash')) return Colors.red;
    if (cat.contains('reserve')) return Colors.blue;
    return MigoColors.primary;
  }

  // കാറ്റഗറി അനുസരിച്ച് ഐക്കൺ നൽകുന്നു
  IconData _getCategoryIcon() {
    final cat = widget.offer.category.toLowerCase();
    if (cat.contains('food')) return Icons.restaurant;
    if (cat.contains('beauty')) return Icons.spa;
    if (cat.contains('supermarket')) return Icons.local_grocery_store;
    if (cat.contains('retail') || cat.contains('shopping')) return Icons.shopping_bag;
    if (cat.contains('flash')) return Icons.flash_on;
    if (cat.contains('reserve')) return Icons.event_available;
    return Icons.local_offer;
  }

  LinearGradient _placeholderGradient() {
    final c = widget.offer.category.toLowerCase();
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
    final categoryColor = _getCategoryColor();
    final offer = widget.offer; // 🆕 എളുപ്പത്തിന്

    // 🆕 സമയം കഴിഞ്ഞോ എന്ന് ചെക്ക് ചെയ്യുന്നു
    final isPromoActive = offer.isPromoted && (offer.promotedUntil == null || offer.promotedUntil!.isAfter(DateTime.now()));

    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: MigoShadows.soft,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: widget.onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image section
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (offer.imageUrl != null && offer.imageUrl!.isNotEmpty)
                            Image.network(
                              offer.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
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
                                );
                              },
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
                          // Type badge (top-left)
                          Positioned(
                            top: 10,
                            left: isAr ? null : 10,
                            right: isAr ? 10 : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getCategoryIcon(), size: 12, color: categoryColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getOfferTypeLabel(offer.type, isAr).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                      color: categoryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Discount badge (top-right)
                          Positioned(
                            top: 10,
                            left: isAr ? 10 : null,
                            right: isAr ? null : 10,
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
                                '${offer.percentOff}% ${isAr ? 'خصم' : 'OFF'}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // 🆕 Promoted Badge (bottom-left)
                          if (isPromoActive)
                            Positioned(
                              bottom: 10,
                              left: isAr ? null : 10,
                              right: isAr ? 10 : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, size: 12, color: Colors.black),
                                    const SizedBox(width: 4),
                                    Text(
                                      isAr ? 'مميز' : 'FEATURED',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Content section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Business name
                            Text(
                              offer.businessName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w800,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            // Title (flex)
                            Expanded(
                              child: Text(
                                isAr ? offer.titleAr : offer.titleEn,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Price row
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
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      '${offer.currency} ${offer.originalPrice.toStringAsFixed(0)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        decoration: TextDecoration.lineThrough,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Save badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: MigoColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isAr
                                    ? 'وفر ${offer.currency} ${offer.savings.toStringAsFixed(0)}'
                                    : 'SAVE ${offer.currency} ${offer.savings.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: MigoColors.success,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Location + verified
                            Row(
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  size: 12,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${widget.distanceKm.toStringAsFixed(1)} ${isAr ? 'كم' : 'km'}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: textSecondary,
                                  ),
                                ),
                                                                const Spacer(),
                                // 🆕 Reviews Star ചേർത്തു
                                FutureBuilder<({double average, int count})>(
                                  future: FirestoreService.instance.getBusinessRating(offer.businessId),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData || snapshot.data!.count == 0) {
                                      return const SizedBox.shrink();
                                    }
                                    final rating = snapshot.data!.average;
                                    return Row(
                                      children: [
                                        const Icon(Icons.star, size: 12, color: Colors.amber),
                                        const SizedBox(width: 2),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87),
                                        ),
                                        Text(
                                          ' (${snapshot.data!.count})',
                                          style: TextStyle(fontSize: 9, color: textSecondary),
                                        ),
                                      ],
                                    );
                                  },
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

  String _getOfferTypeLabel(OfferType type, bool isAr) {
    switch (type) {
      case OfferType.standard:
        return isAr ? 'عرض قياسي' : 'Standard Deal';
      case OfferType.flash:
        return isAr ? 'عرض سريع' : 'Flash Deal';
      case OfferType.group:
        return isAr ? 'عرض جماعي' : 'Group Deal';
      case OfferType.hidden:
        return isAr ? 'جوهرة مخفية' : 'Hidden Gem';
      case OfferType.birthday:
        return isAr ? 'عرض عيد ميلاد' : 'Birthday Deal';
      default:
        return isAr ? 'عرض' : 'Deal';
    }
  }
}