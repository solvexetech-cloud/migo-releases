import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/migo_colors.dart';
import '../../core/theme/migo_gradients.dart';
import '../../core/theme/migo_shadows.dart';
import '../../models/claim_model.dart';
import '../../models/coin_transaction_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: StreamBuilder<UserModel?>(
        stream: FirestoreService.instance.streamUser(uid),
        builder: (context, userSnap) {
          final user = userSnap.data;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Coin balance card
                            Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: MigoGradients.heroBlue,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: MigoShadows.strong,
                ),
                child: Stack(
                  children: [
                    // Decorative circle top-right
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: MigoColors.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 30,
                      bottom: -20,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: MigoGradients.gold,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.monetization_on,
                                color: Colors.black,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'MIGO COINS',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 2.5,
                                fontWeight: FontWeight.w900,
                                color: MigoColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${user?.coins ?? 0}',
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Earn more by claiming and redeeming deals',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Stats grid（from real claims）
              _StatsGrid(uid: uid),

              const SizedBox(height: 20),

              // Savings card（derived from claims）
              _SavingsCard(uid: uid),

              const SizedBox(height: 24),

              const Text(
                'Recent activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: MigoColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 10),

              _ActivityList(uid: uid),

              const SizedBox(height: 24),

              // How to earn more
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MigoColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: MigoColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tips_and_updates_outlined,
                          color: MigoColors.accent,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Earn more coins',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: MigoColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    _EarnRow(icon: Icons.redeem, text: 'Claim a deal  +5'),
                    SizedBox(height: 6),
                    _EarnRow(
                      icon: Icons.qr_code_scanner,
                      text: 'Redeem at business  +25',
                    ),
                    SizedBox(height: 6),
                    _EarnRow(
                      icon: Icons.person_add_alt,
                      text: 'Refer a friend  +50',
                    ),
                    SizedBox(height: 6),
                    _EarnRow(
                      icon: Icons.star_outline,
                      text: 'Write useful review  +10',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ClaimModel>>(
      stream: FirestoreService.instance.streamMyClaims(uid),
      builder: (context, snap) {
        final claims = snap.data ?? [];
        final redeemed = claims
            .where((c) => c.status == ClaimStatus.redeemed)
            .toList();
        final businesses = redeemed.map((c) => c.businessId).toSet().length;

        return Row(
          children: [
            Expanded(
              child: _StatBox(
                label: 'Deals used',
                value: '${redeemed.length}',
                icon: Icons.check_circle_outline,
                color: MigoColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatBox(
                label: 'Businesses',
                value: '$businesses',
                icon: Icons.storefront_outlined,
                color: MigoColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatBox(
                label: 'Claims',
                value: '${claims.length}',
                icon: Icons.receipt_long_outlined,
                color: MigoColors.accent,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MigoColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MigoColors.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: MigoColors.textPrimaryLight,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: MigoColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ClaimModel>>(
      stream: FirestoreService.instance.streamMyClaims(uid),
      builder: (context, snap) {
        final claims = snap.data ?? [];
        final redeemed = claims
            .where((c) => c.status == ClaimStatus.redeemed)
            .toList();

        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final thisMonth = redeemed
            .where((c) => c.redeemedAt?.isAfter(monthStart) ?? false)
            .fold<double>(0, (sum, c) => sum + c.savings);
        final lifetime =
            redeemed.fold<double>(0, (sum, c) => sum + c.savings);
        final currency = claims.isNotEmpty ? claims.first.currency : 'QAR';

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
                  const Icon(
                    Icons.savings_outlined,
                    color: MigoColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Savings',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: MigoColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'This month',
                          style: TextStyle(
                            fontSize: 11,
                            color: MigoColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          '$currency ${thisMonth.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: MigoColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: MigoColors.dividerLight,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lifetime',
                          style: TextStyle(
                            fontSize: 11,
                            color: MigoColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          '$currency ${lifetime.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: MigoColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CoinTransactionModel>>(
      stream: FirestoreService.instance.streamCoinTransactions(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final txs = snap.data ?? [];
        if (txs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MigoColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MigoColors.dividerLight),
            ),
            child: const Center(
              child: Text(
                'No coin activity yet',
                style: TextStyle(color: MigoColors.textSecondaryLight),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: MigoColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MigoColors.dividerLight),
          ),
          child: Column(
            children: List.generate(txs.length, (i) {
              final t = txs[i];
              final isLast = i == txs.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: t.isEarned
                                ? MigoColors.success.withValues(alpha: 0.15)
                                : MigoColors.error.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            t.isEarned ? Icons.add : Icons.remove,
                            color: t.isEarned
                                ? MigoColors.success
                                : MigoColors.error,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.reason,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: MigoColors.textPrimaryLight,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(t.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: MigoColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${t.isEarned ? '+' : ''}${t.amount}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: t.isEarned
                                ? MigoColors.success
                                : MigoColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: MigoColors.dividerLight,
                    ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _EarnRow extends StatelessWidget {
  const _EarnRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: MigoColors.textSecondaryLight),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: MigoColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}