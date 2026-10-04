import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/migo_colors.dart';
import '../../core/theme/migo_gradients.dart';
import '../../core/theme/migo_shadows.dart';
import '../../models/business_model.dart';
import '../../models/review_model.dart';
import '../../services/firestore_service.dart';

class BusinessReviewsScreen extends StatelessWidget {
  const BusinessReviewsScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<BusinessModel?>(
        stream: _streamBusiness(),
        builder: (context, bizSnap) {
          final biz = bizSnap.data;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 140,
                backgroundColor: MigoColors.primary,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    biz?.name ?? businessName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: MigoGradients.heroBlue,
                    ),
                  ),
                ),
              ),
              if (biz != null)
                SliverToBoxAdapter(child: _BusinessHeader(biz: biz)),
              SliverToBoxAdapter(
                child: StreamBuilder<List<ReviewModel>>(
                  stream: FirestoreService.instance
                      .streamBusinessReviews(businessId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final reviews = snap.data ?? [];
                    return _ReviewsList(reviews: reviews);
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  Stream<BusinessModel?> _streamBusiness() {
    return FirestoreService.instance.streamMyBusinessById(businessId);
  }
}

class _BusinessHeader extends StatelessWidget {
  const _BusinessHeader({required this.biz});
  final BusinessModel biz;

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = biz.isOpenNow;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MigoColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: MigoShadows.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: MigoGradients.softBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.storefront,
                        color: MigoColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  biz.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: MigoColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                              if (biz.verified) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified,
                                  color: MigoColors.success,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            biz.category,
                            style: const TextStyle(
                              fontSize: 13,
                              color: MigoColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? MigoColors.success.withValues(alpha: 0.15)
                            : MigoColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? MigoColors.success
                                  : MigoColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isOpen ? 'OPEN' : 'CLOSED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isOpen
                                  ? MigoColors.success
                                  : MigoColors.error,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Hours
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 15,
                      color: MigoColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      biz.hoursLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MigoColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 15,
                      color: MigoColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${biz.addressLine}, ${biz.city}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: MigoColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                if (biz.description != null &&
                    biz.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    biz.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: MigoColors.textSecondaryLight,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    if (biz.phone != null && biz.phone!.isNotEmpty)
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.phone,
                          label: 'Call',
                          color: MigoColors.success,
                          onTap: () =>
                              _openUrl(context, 'tel:${biz.phone}'),
                        ),
                      ),
                    if (biz.whatsapp != null &&
                        biz.whatsapp!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.chat,
                          label: 'WhatsApp',
                          color: MigoColors.success,
                          onTap: () => _openUrl(
                            context,
                            'https://wa.me/${biz.whatsapp!.replaceAll('+', '')}',
                          ),
                        ),
                      ),
                    ],
                    if (biz.mapUrl != null &&
                        biz.mapUrl!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.map_outlined,
                          label: 'Map',
                          color: MigoColors.primary,
                          onTap: () => _openUrl(context, biz.mapUrl!),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewsList extends StatelessWidget {
  const _ReviewsList({required this.reviews});
  final List<ReviewModel> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: MigoColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                boxShadow: MigoShadows.soft,
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 56,
                    color: MigoColors.textSecondaryLight,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Be the first to review this business.',
                    style: TextStyle(
                      fontSize: 13,
                      color: MigoColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final avg =
        reviews.fold<int>(0, (s, r) => s + r.rating) / reviews.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MigoColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: MigoShadows.soft,
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avg.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: MigoColors.textPrimaryLight,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < avg.round();
                        return Icon(
                          filled ? Icons.star : Icons.star_border,
                          size: 16,
                          color: MigoColors.accent,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${reviews.length} '
                        '${reviews.length == 1 ? "review" : "reviews"}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'from verified MIGO customers',
                        style: TextStyle(
                          fontSize: 12,
                          color: MigoColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...reviews.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReviewCard(review: r),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MigoColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: MigoShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: MigoColors.primary,
                child: Icon(Icons.person, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userDisplayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < review.rating;
                        return Icon(
                          filled ? Icons.star : Icons.star_border,
                          size: 14,
                          color: MigoColors.accent,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              if (review.verifiedVisit)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: MigoColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'VERIFIED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: MigoColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 13,
              color: MigoColors.textPrimaryLight,
              height: 1.4,
            ),
          ),
          if (review.offerTitle != null) ...[
            const SizedBox(height: 8),
            Text(
              'on "${review.offerTitle}"',
              style: const TextStyle(
                fontSize: 11,
                color: MigoColors.textSecondaryLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}