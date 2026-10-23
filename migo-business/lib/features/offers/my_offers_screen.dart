import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/migo_theme.dart';
import '../../models/offer_model.dart';
import '../../services/offer_service.dart';
import 'create_offer_screen.dart';
import 'business_offer_reserve_settings.dart';
import 'offer_stats_screen.dart';

/// PHASE I — My Offers (Business)
class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({super.key});

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  String? _businessId;
  String? _businessName;
  String? _areaId;
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
      final data = snap.docs.first.data();
      _businessId = snap.docs.first.id;
      _businessName = data['name'] as String?;
      _areaId = data['areaId'] as String?;
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_businessId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No business linked to your account.\nPlease contact MIGO support.',
            textAlign: TextAlign.center,
            style: TextStyle(color: MigoColors.textSecondary),
          ),
        ),
      );
    }

    return StreamBuilder<List<OfferModel>>(
      stream: OfferService.instance.streamMyOffers(_businessId!),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final offers = snap.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Offers',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${offers.length} total',
                          style: const TextStyle(
                            color: MigoColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openCreate(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (offers.isEmpty)
                _emptyState(context)
              else
                ...offers.map((o) => _offerCard(context, o)),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(
              Icons.local_offer_outlined,
              size: 56,
              color: MigoColors.accent,
            ),
            const SizedBox(height: 12),
            const Text(
              'No offers yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create your first offer to attract customers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: MigoColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openCreate(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Offer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _offerCard(BuildContext context, OfferModel offer) {
    final statusColor = _statusColor(offer.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    offer.title.isEmpty ? 'Untitled' : offer.title,
                    style: const TextStyle(
                      fontSize: 16,
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
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    offer.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              offer.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: MigoColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${offer.currency} ${offer.originalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                    color: MigoColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${offer.currency} ${offer.offerPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: MigoColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: MigoColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SAVE ${offer.discountPercent}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: MigoColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ── Action Buttons Row ──
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: () => _openEdit(context, offer),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Edit', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleActive(context, offer),
                    icon: Icon(
                      offer.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      size: 14,
                    ),
                    label: Text(
                      offer.isActive ? 'Pause' : 'Activate',
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Icons
                _actionIcon(
                  icon: Icons.tune,
                  color: Colors.deepPurple,
                  tooltip: 'Reserve Settings',
                  onPressed: () => _openReserveSettings(context, offer),
                ),
                _actionIcon(
                  icon: Icons.bar_chart,
                  color: MigoColors.info,
                  tooltip: 'View Stats',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OfferStatsScreen(
                          offerId: offer.id,
                          offerTitle: offer.title,
                        ),
                      ),
                    );
                  },
                ),
                _actionIcon(
                  icon: Icons.delete_outline,
                  color: MigoColors.error,
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(context, offer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ചെറിയ ഐക്കൺ ബട്ടൺ ഉണ്ടാക്കാൻ ഒരു ഹെൽപ്പർ
  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 20),
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      visualDensity: VisualDensity.compact,
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'live':
      case 'approved':
        return MigoColors.success;
      case 'pending':
        return MigoColors.warning;
      case 'paused':
      case 'rejected':
        return MigoColors.error;
      default:
        return MigoColors.textSecondary;
    }
  }

  Future<void> _openCreate(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateOfferScreen(
          businessId: _businessId!,
          businessName: _businessName ?? 'Business',
          areaId: _areaId ?? '',
        ),
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, OfferModel offer) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateOfferScreen(
          businessId: _businessId!,
          businessName: _businessName ?? 'Business',
          areaId: _areaId ?? '',
          existingOffer: offer,
        ),
      ),
    );
  }

  Future<void> _toggleActive(
      BuildContext context, OfferModel offer) async {
    final err = await OfferService.instance.toggleActive(
      offerId: offer.id,
      currentActive: offer.isActive,
    );
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
  }

  Future<void> _openReserveSettings(
      BuildContext context, OfferModel offer) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessOfferReserveSettingsScreen(
          offerId: offer.id,
          businessId: _businessId!,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, OfferModel offer) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete offer?'),
        content:
            Text('"${offer.title}" will be deleted permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: MigoColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await OfferService.instance.deleteOffer(offer.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer deleted')),
      );
    }
  }
}