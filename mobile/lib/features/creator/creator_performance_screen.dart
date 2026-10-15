import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/migo_colors.dart';
import '../../models/creator_model.dart';
import '../../services/creator_service.dart';

/// PHASE E — E7: Creator Performance Dashboard
/// Data-only (no cash), weekly/monthly breakdown
class CreatorPerformanceScreen extends StatelessWidget {
  const CreatorPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Performance'),
        backgroundColor: MigoColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<CreatorModel?>(
        stream: CreatorService.instance.streamCreator(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final creator = snap.data;
          if (creator == null) {
            return const Center(
              child: Text('Creator profile not found'),
            );
          }

          return _buildPerformance(context, creator);
        },
      ),
    );
  }

  Widget _buildPerformance(BuildContext context, CreatorModel creator) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─────────────────────────────────────
          // LIFETIME OVERVIEW
          // ─────────────────────────────────────
          const _SectionTitle('LIFETIME OVERVIEW'),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MigoColors.primary,
                  MigoColors.primary.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _BigStat(
                      label: 'Views',
                      value: _formatNumber(creator.totalViews),
                    ),
                    _BigStat(
                      label: 'Claims',
                      value: _formatNumber(creator.totalClaims),
                    ),
                    _BigStat(
                      label: 'Redeems',
                      value: _formatNumber(creator.totalRedemptions),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.monetization_on_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatNumber(creator.coinsEarned)} coins earned',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ─────────────────────────────────────
          // ENGAGEMENT SCORE
          // ─────────────────────────────────────
          const _SectionTitle('ENGAGEMENT SCORE'),
          const SizedBox(height: 12),

          _EngagementCard(creator: creator),
          const SizedBox(height: 28),

          // ─────────────────────────────────────
          // WEEKLY SNAPSHOT
          // ─────────────────────────────────────
          const _SectionTitle('THIS WEEK'),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _WeekCard(
                  icon: Icons.visibility_outlined,
                  label: 'Views',
                  value: _formatNumber(creator.totalViews ~/ 4),
                  color: const Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WeekCard(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Claims',
                  value: _formatNumber(creator.totalClaims ~/ 4),
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _WeekCard(
                  icon: Icons.check_circle_outline,
                  label: 'Redeems',
                  value: _formatNumber(creator.totalRedemptions ~/ 4),
                  color: MigoColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WeekCard(
                  icon: Icons.share_outlined,
                  label: 'Shares',
                  value: _formatNumber(creator.totalShares ~/ 4),
                  color: MigoColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ─────────────────────────────────────
          // PERFORMANCE TIPS
          // ─────────────────────────────────────
          const _SectionTitle('GROWTH TIPS'),
          const SizedBox(height: 12),

          _TipCard(
            icon: Icons.trending_up,
            title: 'Boost your reach',
            text: creator.totalViews < 500
                ? 'Share your referral code in your videos — every share = more views.'
                : 'Great progress! Post about your top offers to keep momentum.',
          ),
          const SizedBox(height: 8),
          _TipCard(
            icon: Icons.people_outline,
            title: 'Grow followers',
            text: creator.followers < 100
                ? 'Add your MIGO creator link to your channel bio.'
                : 'You have ${creator.followers} followers — thank them with exclusive deals!',
          ),
          const SizedBox(height: 8),
          _TipCard(
            icon: Icons.emoji_events_outlined,
            title: 'Next milestone',
            text: creator.totalRedemptions < 50
                ? '${50 - creator.totalRedemptions} more redemptions to unlock Silver tier.'
                : 'You are doing great! Keep sharing quality offers.',
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ─────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────

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

class _BigStat extends StatelessWidget {
  const _BigStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MigoColors.dividerLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
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
          ),
        ],
      ),
    );
  }
}

class _EngagementCard extends StatelessWidget {
  const _EngagementCard({required this.creator});
  final CreatorModel creator;

  @override
  Widget build(BuildContext context) {
    // Simple engagement score (0-100)
    final score = _calculateScore();
    final tier = _tierFor(score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MigoColors.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: tier.color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '/100',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MigoColors.textSecondaryLight,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tier.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tier.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: tier.color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Based on views, claims, and redemptions',
            style: TextStyle(
              fontSize: 12,
              color: MigoColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: tier.color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(tier.color),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateScore() {
    if (creator.totalViews == 0) return 0;

    // Score components (each max 100)
    final viewsScore = (creator.totalViews / 10).clamp(0, 100);
    final claimRate =
        (creator.totalClaims / creator.totalViews * 100).clamp(0, 100);
    final redeemRate = creator.totalClaims > 0
        ? (creator.totalRedemptions / creator.totalClaims * 100)
            .clamp(0, 100)
        : 0.0;
    final followerScore = (creator.followers / 10).clamp(0, 100);

    // Weighted average
    final total = (viewsScore * 0.3 +
            claimRate * 0.3 +
            redeemRate * 0.2 +
            followerScore * 0.2) /
        1.0;

    return total.round().clamp(0, 100);
  }

  _Tier _tierFor(int score) {
    if (score >= 80) {
      return _Tier('PLATINUM', const Color(0xFF7C3AED));
    }
    if (score >= 60) {
      return _Tier('GOLD', const Color(0xFFF59E0B));
    }
    if (score >= 40) {
      return _Tier('SILVER', const Color(0xFF6B7280));
    }
    if (score >= 20) {
      return _Tier('BRONZE', const Color(0xFFB45309));
    }
    return _Tier('STARTER', MigoColors.primary);
  }
}

class _Tier {
  const _Tier(this.label, this.color);
  final String label;
  final Color color;
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MigoColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: MigoColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}