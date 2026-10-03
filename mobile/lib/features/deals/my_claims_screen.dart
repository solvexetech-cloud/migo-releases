import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/claim_model.dart';
import '../../services/firestore_service.dart';
import 'claim_detail_screen.dart';

class MyClaimsScreen extends StatelessWidget {
  const MyClaimsScreen({super.key});

  Color _statusColor(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.active:
        return MigoColors.primary;
      case ClaimStatus.redeemed:
        return MigoColors.success;
      case ClaimStatus.expired:
        return MigoColors.textSecondaryLight;
      case ClaimStatus.cancelled:
        return MigoColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Claims')),
      body: StreamBuilder<List<ClaimModel>>(
        stream: FirestoreService.instance.streamMyClaims(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final claims = snap.data ?? [];
          if (claims.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: MigoColors.primary,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No claims yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Claim an offer from Home to see it here.',
                      textAlign: TextAlign.center,
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

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: claims.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final c = claims[i];
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ClaimDetailScreen(claim: c),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
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
                            child: Text(
                              c.offerTitle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(c.status)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c.status.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _statusColor(c.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.businessName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: MigoColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            '${c.currency} ${c.originalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: MigoColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${c.currency} ${c.offerPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: MigoColors.primary,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.qr_code_2,
                            size: 20,
                            color: MigoColors.primary,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'View QR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: MigoColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}