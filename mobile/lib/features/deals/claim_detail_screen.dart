import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/claim_model.dart';

class ClaimDetailScreen extends StatelessWidget {
  const ClaimDetailScreen({super.key, required this.claim});
  final ClaimModel claim;

  Color _statusColor() {
    switch (claim.status) {
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
    final now = DateTime.now();
    final isExpiredByTime = claim.expiresAt.isBefore(now);
    final canRedeem =
        claim.status == ClaimStatus.active && !isExpiredByTime;

    return Scaffold(
      appBar: AppBar(title: const Text('Claim')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                                child: Text(
                  isExpiredByTime && claim.status == ClaimStatus.active
                      ? 'EXPIRED'
                      : claim.status.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isExpiredByTime &&
                            claim.status == ClaimStatus.active
                        ? MigoColors.error
                        : _statusColor(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: MigoColors.dividerLight),
                ),
                child: Column(
                  children: [
                    Opacity(
                      opacity: canRedeem ? 1.0 : 0.3,
                      child: QrImageView(
                        data: claim.id,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: MigoColors.primary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: MigoColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                                        Text(
                      canRedeem
                          ? 'Show this to the business'
                          : claim.status == ClaimStatus.redeemed
                              ? 'Already redeemed'
                              : isExpiredByTime
                                  ? 'This claim has expired'
                                  : 'Not valid',
                      style: const TextStyle(
                        fontSize: 13,
                        color: MigoColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: MigoColors.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        claim.id,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: MigoColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MigoColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MigoColors.dividerLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.offerTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      claim.businessName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: MigoColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${claim.currency} ${claim.originalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough,
                            color: MigoColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${claim.currency} ${claim.offerPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: MigoColors.primary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                MigoColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SAVE ${claim.currency} ${claim.savings.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: MigoColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (claim.status == ClaimStatus.redeemed &&
                        claim.redeemedAt != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 14,
                            color: MigoColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Redeemed ${claim.redeemedAt!.toLocal().toString().split('.').first}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: MigoColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
                            Text(
                isExpiredByTime && claim.status == ClaimStatus.active
                    ? 'This claim expired on '
                        '${claim.expiresAt.toLocal().toString().split('.').first}.\n'
                        'You can no longer redeem this offer.'
                    : '1. Visit the business during your claim validity period.\n'
                        '2. Show this QR code (or the short code) to the staff.\n'
                        '3. They will scan it to confirm your redemption.\n'
                        '4. You will earn +25 MIGO Coins after redemption.',
                style: TextStyle(
                  fontSize: 13,
                  color: MigoColors.textSecondaryLight,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}