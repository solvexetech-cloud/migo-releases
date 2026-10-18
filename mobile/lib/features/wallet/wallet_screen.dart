import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/app_config.dart';
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
      body: StreamBuilder<UserModel?>(
        stream: FirestoreService.instance.streamUser(uid),
        builder: (context, userSnap) {
          final user = userSnap.data;
          return CustomScrollView(
            slivers: [
              // Deep Blue gradient header with coin card
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: MigoGradients.heroBlue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Wallet',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Coin card
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -20,
                                  top: -20,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: MigoColors.accent
                                          .withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            gradient: MigoGradients.gold,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.monetization_on,
                                            color: Colors.black,
                                            size: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'MIGO COINS',
                                          style: TextStyle(
                                            fontSize: 10,
                                            letterSpacing: 2.5,
                                            fontWeight: FontWeight.w900,
                                            color: MigoColors.accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      '${user?.coins ?? 0}',
                                      style: const TextStyle(
                                        fontSize: 54,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1,
                                        letterSpacing: -2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats grid
                      _StatsGrid(uid: uid),
                      const SizedBox(height: 20),
                      // Savings
                      _SavingsCard(uid: uid, user: user),
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
                      // Earn more
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              MigoColors.accent.withValues(alpha: 0.12),
                              MigoColors.accent.withValues(alpha: 0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
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
                                  color: MigoColors.accentDark,
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
                            _EarnRow(
                              icon: Icons.qr_code_scanner,
                              text: 'Redeem at business  +5',
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
                  ),
                ),
              ),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('userUid', isEqualTo: uid)
          .where('status', isEqualTo: 'picked_up')
          .snapshots(),
      builder: (context, snap) {
        final reservations = snap.data?.docs ?? [];
        final businesses = reservations
            .map((doc) => doc['businessId'] as String?)
            .where((id) => id != null)
            .toSet()
            .length;

        return Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Deals used',
                value: '${reservations.length}',
                icon: Icons.check_circle_outline,
                color: MigoColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: 'Businesses',
                value: '$businesses',
                icon: Icons.storefront_outlined,
                color: MigoColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: 'Redeemed',
                value: '${reservations.length}',
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

class _StatTile extends StatelessWidget {
  const _StatTile({
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
        boxShadow: MigoShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: MigoColors.textPrimaryLight,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: MigoColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({required this.uid, this.user});
  final String uid;
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('userUid', isEqualTo: uid)
          .where('status', isEqualTo: 'picked_up')
          .snapshots(),
      builder: (context, snap) {
        final reservations = snap.data?.docs ?? [];

        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        
        double thisMonth = 0;
        double lifetime = 0;

        for (final doc in reservations) {
          final data = doc.data() as Map<String, dynamic>;
          final savings = ((data['originalPrice'] as num?)?.toDouble() ?? 0) - 
                          ((data['unitPrice'] as num?)?.toDouble() ?? 0);
          
          lifetime += savings;
          
          final pickedUpAt = (data['pickedUpAt'] as Timestamp?)?.toDate();
          if (pickedUpAt != null && pickedUpAt.isAfter(monthStart)) {
            thisMonth += savings;
          }
        }

        final currency = user?.currency ?? AppConfig.fallbackCurrency;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: MigoGradients.success,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: MigoColors.success.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.savings, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'YOUR SAVINGS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$currency ${thisMonth.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.3),
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
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$currency ${lifetime.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1,
                            letterSpacing: -0.5,
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
              boxShadow: MigoShadows.soft,
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
            borderRadius: BorderRadius.circular(16),
            boxShadow: MigoShadows.soft,
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
                            gradient: t.isEarned
                                ? MigoGradients.success
                                : MigoGradients.flash,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            t.isEarned ? Icons.add : Icons.remove,
                            color: Colors.white,
                            size: 14,
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
                            fontWeight: FontWeight.w900,
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
        Icon(icon, size: 16, color: MigoColors.accentDark),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: MigoColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}