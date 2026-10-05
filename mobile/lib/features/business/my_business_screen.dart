import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/business_model.dart';
import '../../models/offer_model.dart';
import '../../services/firestore_service.dart';
import 'business_analytics_screen.dart';
import 'create_offer_screen.dart';
import 'redeem_screen.dart';
import 'register_business_screen.dart';

class MyBusinessScreen extends StatelessWidget {
  const MyBusinessScreen({super.key});

  Future<void> _openRegister(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterBusinessScreen()),
    );
  }

  Future<void> _openCreateOffer(
    BuildContext context,
    BusinessModel business,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateOfferScreen(business: business),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return MigoColors.success;
      case 'pending':
        return MigoColors.warning;
      case 'rejected':
      case 'suspended':
        return MigoColors.error;
      default:
        return MigoColors.textSecondaryLight;
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
      appBar: AppBar(title: const Text('My Business')),
      body: StreamBuilder<BusinessModel?>(
        stream: FirestoreService.instance.streamMyBusiness(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final biz = snap.data;
          if (biz == null) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.storefront_outlined,
                    size: 72,
                    color: MigoColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No business yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Register your business to start publishing offers on MIGO.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: MigoColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openRegister(context),
                      icon: const Icon(Icons.add_business_outlined),
                      label: const Text('Register business'),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
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
                        Expanded(
                          child: Text(
                            biz.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(biz.status)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            biz.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _statusColor(biz.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      biz.category,
                      style: const TextStyle(
                        color: MigoColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: MigoColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            biz.addressLine,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (biz.status == 'pending')
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: MigoColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: MigoColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.schedule, color: MigoColors.warning),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your business is under review.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              if (biz.status == 'approved') ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: MigoColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: MigoColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, color: MigoColors.success),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Approved! Create your first offer below.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _openCreateOffer(context, biz),
                    icon: const Icon(Icons.add),
                    label: const Text('Create offer'),
                  ),
                ),
                                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RedeemScreen(business: biz),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Redeem claim'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              BusinessAnalyticsScreen(business: biz),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('View analytics'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'YOUR OFFERS',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: MigoColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 10),
             _MyOffersList(businessId: biz.id, business: biz),
            ],
          );
        },
      ),
    );
  }
}

class _MyOffersList extends StatelessWidget {
  const _MyOffersList({
    required this.businessId,
    required this.business,
  });
  final String businessId;
  final BusinessModel business;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OfferModel>>(
      stream: FirestoreService.instance.streamMyOffers(businessId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final offers = snap.data ?? [];
        if (offers.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MigoColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MigoColors.dividerLight),
            ),
            child: const Center(
              child: Text(
                'No offers yet',
                style: TextStyle(color: MigoColors.textSecondaryLight),
              ),
            ),
          );
        }

        return Column(
          children: offers.map((o) {
            final statusColor = o.status == 'live'
                ? MigoColors.success
                : o.status == 'pending'
                    ? MigoColors.warning
                    : MigoColors.textSecondaryLight;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: MigoColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MigoColors.dividerLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          o.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
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
                          o.status.toUpperCase(),
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
                    o.type.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MigoColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${o.currency} ${o.originalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          color: MigoColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${o.currency} ${o.offerPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: MigoColors.primary,
                        ),
                      ),
                      const Spacer(),
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
                          'SAVE ${o.currency} ${o.savings.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: MigoColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (o.isExpired)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: MigoColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'EXPIRED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: MigoColors.error,
                            ),
                          ),
                        ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CreateOfferScreen(
                                business: business,
                                initialOffer: o,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_outlined, size: 14),
                        label: const Text(
                          'Duplicate',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}