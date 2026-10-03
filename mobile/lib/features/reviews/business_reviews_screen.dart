import 'package:flutter/material.dart';
import '../../core/theme/migo_colors.dart';
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
      appBar: AppBar(title: Text(businessName)),
      body: StreamBuilder<List<ReviewModel>>(
        stream:
            FirestoreService.instance.streamBusinessReviews(businessId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reviews = snap.data ?? [];
          if (reviews.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 64,
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
            );
          }

          final avg = reviews.fold<int>(0, (s, r) => s + r.rating) /
              reviews.length;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: MigoColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MigoColors.dividerLight),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          avg.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 40,
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
                              size: 18,
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
              const SizedBox(height: 20),
              ...reviews.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReviewCard(review: r),
                ),
              ),
            ],
          );
        },
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MigoColors.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: MigoColors.primary,
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: Colors.white,
                ),
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