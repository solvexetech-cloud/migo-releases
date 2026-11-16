import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/creator_model.dart';
import '../../services/creator_service.dart';
import 'creator_analytics_screen.dart';
import 'creator_profile_screen.dart';
import 'creator_performance_screen.dart';
import 'edit_creator_profile_screen.dart';

class CreatorDashboardScreen extends StatelessWidget {
  const CreatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: MigoColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<CreatorModel?>(
        stream: FirebaseFirestore.instance.collection('creators').where('userId', isEqualTo: uid).snapshots().map((snap) => snap.docs.isNotEmpty ? CreatorModel.fromMap(snap.docs.first.id, snap.docs.first.data()) : null),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final creator = snap.data;
          if (creator == null) {
            return const Center(child: Text('Creator profile not found'));
          }

          if (!creator.isApproved) {
            return _buildPending(context, creator);
          }

          return _buildDashboard(context, creator);
        },
      ),
    );
  }

  Widget _buildPending(BuildContext context, CreatorModel creator) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            creator.status == CreatorStatus.rejected ? Icons.cancel_outlined : Icons.schedule,
            size: 72,
            color: creator.status == CreatorStatus.rejected ? MigoColors.error : MigoColors.warning,
          ),
          const SizedBox(height: 20),
          Text(
            creator.status == CreatorStatus.rejected ? 'Application Rejected' : 'Application Pending',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                border: Border.all(color: MigoColors.warning.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: MigoColors.warning),
                  SizedBox(width: 12),
                  Expanded(child: Text('You will be notified once approved.', style: TextStyle(fontSize: 13))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, CreatorModel creator) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card (Profile Info)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [MigoColors.primary, MigoColors.primary.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: creator.profileImageUrl != null ? NetworkImage(creator.profileImageUrl!) : null,
                  child: creator.profileImageUrl == null
                      ? Text(
                          creator.displayName.isNotEmpty ? creator.displayName[0].toUpperCase() : 'C',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creator.displayName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CREATOR',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats Grid
          Row(
            children: [
              Expanded(child: _StatCard(icon: 'Followers', label: 'Followers', value: _formatNumber(creator.followers), color: MigoColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(icon: 'Coins', label: 'Coins', value: _formatNumber(creator.coinsEarned), color: MigoColors.success)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard(icon: 'Shares', label: 'Shares', value: _formatNumber(creator.totalShares), color: const Color(0xFF7C3AED))),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(icon: 'Redemptions', label: 'Redemptions', value: _formatNumber(creator.totalRedemptions), color: MigoColors.warning)),
            ],
          ),
          const SizedBox(height: 24),

          // ðŸ†• Earnings Section
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                           const Text('Total Coins', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance.collection('creator_earnings').where('creatorId', isEqualTo: creator.userId).get(),
                        builder: (context, snap) {
                          if (!snap.hasData) return const Text('...', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: MigoColors.primary));
                          double total = 0;
                          for (var doc in snap.data!.docs) {
                            total += (doc.data() as Map<String, dynamic>)['amount'] as double? ?? 0;
                          }
                          return Text('${total.toStringAsFixed(0)} Coins', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: MigoColors.primary));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                          const Text('Pending Coins', style: TextStyle(fontSize: 12, color: Colors.orange)),
                      const SizedBox(height: 8),
                      FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance.collection('creator_earnings').where('creatorId', isEqualTo: creator.userId).where('status', isEqualTo: 'pending').get(),
                        builder: (context, snap) {
                          if (!snap.hasData) return const Text('...', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange));
                          double pending = 0;
                          for (var doc in snap.data!.docs) {
                            pending += (doc.data() as Map<String, dynamic>)['amount'] as double? ?? 0;
                          }
                          return Text('${pending.toStringAsFixed(0)} Coins', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout request feature coming soon!')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.grey.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Request Payout'),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text('Recent Coin Earnings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No earnings yet.', style: TextStyle(color: Colors.grey)),
            ),
          ),

          const SizedBox(height: 24),

          // Creator Code
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
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: MigoColors.textSecondaryLight),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        creator.referralCode,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: MigoColors.primary, letterSpacing: 2),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!')));
                      },
                      icon: const Icon(Icons.copy),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditCreatorProfileScreen(creatorId: creator.id)));
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit My Profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: MigoColors.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreatorAnalyticsScreen()));
              },
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('View Analytics', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: MigoColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share feature coming soon!')));
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share My Profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: MigoColors.primary,
                side: const BorderSide(color: MigoColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreatorProfileScreen(creatorId: uid)));
                }
              },
              icon: const Icon(Icons.person_outline),
              label: const Text('View Public Profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: MigoColors.primary,
                side: const BorderSide(color: MigoColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreatorPerformanceScreen()));
              },
              icon: const Icon(Icons.trending_up),
              label: const Text('My Performance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: MigoColors.primary,
                side: const BorderSide(color: MigoColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

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
          Text(icon, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: MigoColors.textSecondaryLight)),
        ],
      ),
    );
  }
}