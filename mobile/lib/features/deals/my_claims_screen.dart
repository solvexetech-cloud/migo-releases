import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/claim_model.dart';
import '../reviews/write_review_screen.dart';

class MyClaimsScreen extends StatelessWidget {
  const MyClaimsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Claims')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('userUid', isEqualTo: uid)
            .where('status', isEqualTo: 'picked_up')
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final reservations = snap.data?.docs ?? [];

          if (reservations.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 64, color: MigoColors.primary),
                    SizedBox(height: 12),
                    Text('No used offers yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Redeem an offer at a business to see it here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: MigoColors.textSecondaryLight)),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: reservations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final doc = reservations[i];
              final data = doc.data() as Map<String, dynamic>;
              
              final title = data['offerTitle'] as String? ?? 'Offer';
              final businessName = data['businessName'] as String? ?? 'Business';
              final originalPrice = (data['originalPrice'] as num?)?.toDouble() ?? 0;
              final offerPrice = (data['unitPrice'] as num?)?.toDouble() ?? 0;
              final currency = data['currency'] as String? ?? 'QAR';
              
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
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
                            Expanded(
                              child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: MigoColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('PICKED UP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: MigoColors.success)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(businessName, style: const TextStyle(fontSize: 12, color: MigoColors.textSecondaryLight)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text('$currency ${originalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: MigoColors.textSecondaryLight)),
                            const SizedBox(width: 6),
                            Text('$currency ${offerPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: MigoColors.primary)),
                            const Spacer(),
                            const Icon(Icons.check_circle, size: 20, color: MigoColors.success),
                            const SizedBox(width: 4),
                            const Text('Used', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MigoColors.success)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final res = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => WriteReviewScreen(
                              claim: ClaimModel(
                                id: doc.id,
                                userUid: uid,
                                businessId: data['businessId'] ?? '',
                                businessName: data['businessName'] ?? '',
                                offerId: data['offerId'] ?? '',
                                offerTitle: data['offerTitle'] ?? '',
                                originalPrice: (data['originalPrice'] as num?)?.toDouble() ?? 0,
                                offerPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0,
                                currency: data['currency'] ?? 'QAR',
                                status: ClaimStatus.redeemed,
                                claimedAt: (data['bookedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                                expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
                                redeemedAt: (data['pickedUpAt'] as Timestamp?)?.toDate(),
                              ),
                            ),
                          ),
                        );
                        if (res == true && context.mounted) {
                          // Review submitted
                        }
                      },
                      icon: const Icon(Icons.rate_review_outlined, size: 16),
                      label: const Text('Write a review · +10 coins'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}