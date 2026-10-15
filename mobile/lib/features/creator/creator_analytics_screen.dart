import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/migo_colors.dart';
import '../../models/creator_model.dart';
import '../../services/creator_service.dart';

/// PHASE E — E6: Creator Analytics
class CreatorAnalyticsScreen extends StatelessWidget {
  const CreatorAnalyticsScreen({super.key});

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
        title: const Text('Analytics'),
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

          return _buildAnalytics(context, creator);
        },
      ),
    );
  }

  Widget _buildAnalytics(BuildContext context, CreatorModel creator) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview title
          const Text(
            'OVERVIEW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: MigoColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),

          // 4 stats grid
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.visibility_outlined,
                  label: 'Views',
                  value: _formatNumber(creator.totalViews),
                  color: const Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Claims',
                  value: _formatNumber(creator.totalClaims),
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.check_circle_outline,
                  label: 'Redemptions',
                  value: _formatNumber(creator.totalRedemptions),
                  color: MigoColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  icon: Icons.monetization_on_outlined,
                  label: 'Coins',
                  value: _formatNumber(creator.coinsEarned),
                  color: MigoColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Conversion rate
          const Text(
            'CONVERSION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: MigoColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MigoColors.dividerLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ConversionRow(
                  label: 'View → Claim',
                  percent: creator.totalViews > 0
                      ? (creator.totalClaims / creator.totalViews * 100)
                      : 0,
                  color: const Color(0xFF7C3AED),
                ),
                const SizedBox(height: 16),
                _ConversionRow(
                  label: 'Claim → Redeem',
                  percent: creator.totalClaims > 0
                      ? (creator.totalRedemptions /
                              creator.totalClaims *
                              100)
                      : 0,
                  color: MigoColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Recent activity
          const Text(
            'PERFORMANCE TIPS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: MigoColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          _TipCard(
            icon: Icons.share_outlined,
            text: creator.totalViews < 100
                ? 'Share more offers to get more views!'
                : 'Great! Keep sharing to grow your audience.',
          ),
          const SizedBox(height: 8),
          _TipCard(
            icon: Icons.trending_up,
            text: creator.totalRedemptions < 10
                ? 'Get at least 10 redemptions to unlock better rewards.'
                : 'Excellent! Your followers love your deals.',
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

class _StatBox extends StatelessWidget {
  const _StatBox({
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
        borderRadius: BorderRadius.circular(14),
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
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: MigoColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversionRow extends StatelessWidget {
  const _ConversionRow({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${clamped.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clamped / 100,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.icon, required this.text});

  final IconData icon;
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
        children: [
          Icon(icon, color: MigoColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}