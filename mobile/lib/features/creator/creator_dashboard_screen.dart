import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/migo_colors.dart';
import '../../models/creator_model.dart';
import '../../services/creator_service.dart';

/// PHASE E — E6: Creator Dashboard
class CreatorDashboardScreen extends StatelessWidget {
  const CreatorDashboardScreen({super.key});

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
        title: const Text('Creator Dashboard'),
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

          if (!creator.isApproved) {
            return _buildPending(context, creator);
          }

          return _buildDashboard(context, creator);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // PENDING STATE
  // ─────────────────────────────────────────────────────
  Widget _buildPending(BuildContext context, CreatorModel creator) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            creator.status == CreatorStatus.rejected
                ? Icons.cancel_outlined
                : Icons.schedule,
            size: 72,
            color: creator.status == CreatorStatus.rejected
                ? MigoColors.error
                : MigoColors.warning,
          ),
          const SizedBox(height: 20),
          Text(
            creator.status == CreatorStatus.rejected
                ? 'Application Rejected'
                : 'Application Pending',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            creator.status == CreatorStatus.rejected
                ? 'Your creator application was not approved.'
                : 'Our team will review your application soon.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: MigoColors.textSecondaryLight),
          ),
          const SizedBox(height: 24),
          if (creator.status == CreatorStatus.pending)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MigoColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: MigoColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: MigoColors.warning),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You will be notified once approved.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // DASHBOARD
  // ─────────────────────────────────────────────────────
  Widget _buildDashboard(BuildContext context, CreatorModel creator) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    creator.displayName.isNotEmpty
                        ? creator.displayName[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creator.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '🎬 CREATOR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: '👥',
                  label: 'Followers',
                  value: _formatNumber(creator.followers),
                  color: MigoColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: '💰',
                  label: 'Coins',
                  value: _formatNumber(creator.coinsEarned),
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
                  icon: '📤',
                  label: 'Shares',
                  value: _formatNumber(creator.totalShares),
                  color: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: '🎯',
                  label: 'Redemptions',
                  value: _formatNumber(creator.totalRedemptions),
                  color: MigoColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Referral code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MigoColors.dividerLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR CREATOR CODE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: MigoColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        creator.referralCode,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: MigoColors.primary,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Copy to clipboard
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Coming soon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MigoColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.construction, color: MigoColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'More features coming soon: Share links, Analytics, Public profile.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final String icon;
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
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
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
              fontSize: 12,
              color: MigoColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}