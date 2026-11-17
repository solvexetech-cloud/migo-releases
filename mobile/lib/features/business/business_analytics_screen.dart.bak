import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/migo_colors.dart';

/// PHASE E — E9: Business Analytics (Referrer Tracking)
/// Shows which creators brought claims/redeems
class BusinessAnalyticsScreen extends StatefulWidget {
  const BusinessAnalyticsScreen({super.key});

  @override
  State<BusinessAnalyticsScreen> createState() =>
      _BusinessAnalyticsScreenState();
}

class _BusinessAnalyticsScreenState extends State<BusinessAnalyticsScreen> {
  String? _businessId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection('businesses')
        .where('ownerUid', isEqualTo: uid)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      _businessId = snap.docs.first.id;
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referrer Analytics'),
        backgroundColor: MigoColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _businessId == null
              ? const Center(child: Text('No business found'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('claims')
          .where('businessId', isEqualTo: _businessId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final claims = snap.data?.docs ?? [];

        if (claims.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No claims yet.\nShare your offers to attract creators!',
                textAlign: TextAlign.center,
                style: TextStyle(color: MigoColors.textSecondaryLight),
              ),
            ),
          );
        }

        // Aggregate by referrer
        final Map<String, _ReferrerStats> stats = {};
        int totalClaims = 0;
        int totalRedeems = 0;

        for (final doc in claims) {
          final data = doc.data() as Map<String, dynamic>;
          totalClaims++;

          final referredBy = data['referredByCreatorId'] as String?;
          final isRedeemed = data['status'] == 'redeemed';

          if (isRedeemed) totalRedeems++;

          if (referredBy != null && referredBy.isNotEmpty) {
            final existing = stats[referredBy];
            if (existing == null) {
              stats[referredBy] = _ReferrerStats(
                creatorId: referredBy,
                claims: 1,
                redeems: isRedeemed ? 1 : 0,
              );
            } else {
              existing.claims++;
              if (isRedeemed) existing.redeems++;
            }
          }
        }

        final sorted = stats.values.toList()
          ..sort((a, b) => b.claims.compareTo(a.claims));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview stats
              const _SectionTitle('OVERVIEW'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Total Claims',
                      value: totalClaims.toString(),
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_outline,
                      label: 'Redeemed',
                      value: totalRedeems.toString(),
                      color: MigoColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people_outline,
                      label: 'Referrers',
                      value: sorted.length.toString(),
                      color: const Color(0xFF0EA5E9),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.trending_up,
                      label: 'Conversion',
                      value: totalClaims > 0
                          ? '${(totalRedeems / totalClaims * 100).toStringAsFixed(0)}%'
                          : '0%',
                      color: MigoColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Top referrers
              if (sorted.isNotEmpty) ...[
                const _SectionTitle('TOP REFERRERS'),
                const SizedBox(height: 12),
                ...sorted.take(10).map(
                      (s) => _ReferrerTile(
                        stats: s,
                        rank: sorted.indexOf(s) + 1,
                      ),
                    ),
                const SizedBox(height: 16),
              ] else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MigoColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: MigoColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No creator referrals yet. Creators will appear here when their followers claim your offers.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ReferrerStats {
  _ReferrerStats({
    required this.creatorId,
    required this.claims,
    required this.redeems,
  });

  final String creatorId;
  int claims;
  int redeems;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: MigoColors.textSecondaryLight,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MigoColors.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
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

class _ReferrerTile extends StatelessWidget {
  const _ReferrerTile({required this.stats, required this.rank});

  final _ReferrerStats stats;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final conversion = stats.claims > 0
        ? (stats.redeems / stats.claims * 100).toStringAsFixed(0)
        : '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MigoColors.dividerLight),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _rankColor(rank).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: _rankColor(rank),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Creator info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Creator ${stats.creatorId.substring(0, 6)}...',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${stats.claims} claims • ${stats.redeems} redeems',
                  style: const TextStyle(
                    fontSize: 12,
                    color: MigoColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          // Conversion %
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: MigoColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$conversion%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: MigoColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFF59E0B); // gold
      case 2:
        return const Color(0xFF9CA3AF); // silver
      case 3:
        return const Color(0xFFB45309); // bronze
      default:
        return MigoColors.primary;
    }
  }
}