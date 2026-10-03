import 'package:flutter/material.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/business_model.dart';
import '../../models/claim_model.dart';
import '../../models/offer_model.dart';
import '../../services/firestore_service.dart';

class BusinessAnalyticsScreen extends StatelessWidget {
  const BusinessAnalyticsScreen({super.key, required this.business});
  final BusinessModel business;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: StreamBuilder<List<ClaimModel>>(
        stream:
            FirestoreService.instance.streamBusinessClaims(business.id),
        builder: (context, claimSnap) {
          return StreamBuilder<List<OfferModel>>(
            stream: FirestoreService.instance.streamMyOffers(business.id),
            builder: (context, offerSnap) {
              if (claimSnap.connectionState == ConnectionState.waiting ||
                  offerSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final claims = claimSnap.data ?? [];
              final offers = offerSnap.data ?? [];

              final totalClaims = claims.length;
              final totalRedeemed = claims
                  .where((c) => c.status == ClaimStatus.redeemed)
                  .length;
              final activeClaims = claims
                  .where((c) => c.status == ClaimStatus.active)
                  .length;

              final revenue = claims
                  .where((c) => c.status == ClaimStatus.redeemed)
                  .fold<double>(0, (sum, c) => sum + c.offerPrice);

              final customerUids = claims.map((c) => c.userUid).toList();
              final uniqueCustomers = customerUids.toSet().length;

              final repeatCustomers = customerUids
                  .where((uid) =>
                      customerUids.where((u) => u == uid).length >= 2)
                  .toSet()
                  .length;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _HeaderCard(
                    businessName: business.name,
                    currency: business.currency,
                    revenue: revenue,
                  ),
                  const SizedBox(height: 20),

                  const _SectionLabel('PERFORMANCE'),
                  const SizedBox(height: 10),
                  _StatGrid(
                    items: [
                      _StatData(
                        label: 'Total claims',
                        value: '$totalClaims',
                        icon: Icons.receipt_long_outlined,
                        color: MigoColors.primary,
                      ),
                      _StatData(
                        label: 'Redeemed',
                        value: '$totalRedeemed',
                        icon: Icons.verified_outlined,
                        color: MigoColors.success,
                      ),
                      _StatData(
                        label: 'Active',
                        value: '$activeClaims',
                        icon: Icons.schedule_outlined,
                        color: MigoColors.warning,
                      ),
                      _StatData(
                        label: 'Customers',
                        value: '$uniqueCustomers',
                        icon: Icons.people_outline,
                        color: MigoColors.primaryLight,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const _SectionLabel('REPEAT CUSTOMERS'),
                  const SizedBox(height: 10),
                  _HighlightCard(
                    title: '$repeatCustomers',
                    subtitle:
                        'customers with 2 or more claims at ${business.name}',
                    icon: Icons.favorite_outline,
                    color: MigoColors.accent,
                  ),

                  const SizedBox(height: 20),
                  const _SectionLabel('OFFERS'),
                  const SizedBox(height: 10),
                  if (offers.isEmpty)
                    const _EmptyCard(message: 'No offers yet')
                  else
                    ...offers.map(
                      (o) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OfferStatRow(
                          offer: o,
                          totalClaims: claims
                              .where((c) => c.offerId == o.id)
                              .length,
                          redemptions: claims
                              .where((c) =>
                                  c.offerId == o.id &&
                                  c.status == ClaimStatus.redeemed)
                              .length,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  const _SectionLabel('CLAIM SOURCES'),
                  const SizedBox(height: 10),
                  _SourceBreakdown(claims: claims),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.businessName,
    required this.currency,
    required this.revenue,
  });

  final String businessName;
  final String currency;
  final double revenue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MigoColors.primary, MigoColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: MigoColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'MEASURABLE REVENUE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                  color: MigoColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$currency ${revenue.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Based on redeemed MIGO offers',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
        color: MigoColors.textSecondaryLight,
      ),
    );
  }
}

class _StatData {
  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.items});
  final List<_StatData> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: items
          .map((s) => Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MigoColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MigoColors.dividerLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(s.icon, color: s.color, size: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.value,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: MigoColors.textPrimaryLight,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.label,
                          style: const TextStyle(
                            fontSize: 11,
                            color: MigoColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: MigoColors.textSecondaryLight,
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

class _OfferStatRow extends StatelessWidget {
  const _OfferStatRow({
    required this.offer,
    required this.totalClaims,
    required this.redemptions,
  });

  final OfferModel offer;
  final int totalClaims;
  final int redemptions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                  offer.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                offer.type.label,
                style: const TextStyle(
                  fontSize: 11,
                  color: MigoColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Claims',
                  value: '$totalClaims',
                  color: MigoColors.primary,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Redeemed',
                  value: '$redemptions',
                  color: MigoColors.success,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Revenue',
                  value:
                      '${offer.currency} ${(redemptions * offer.offerPrice).toStringAsFixed(0)}',
                  color: MigoColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: MigoColors.textSecondaryLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SourceBreakdown extends StatelessWidget {
  const _SourceBreakdown({required this.claims});
  final List<ClaimModel> claims;

  @override
  Widget build(BuildContext context) {
    if (claims.isEmpty) {
      return const _EmptyCard(message: 'No claims yet');
    }

    final grouped = <String, int>{};
    for (final c in claims) {
      grouped[c.source] = (grouped[c.source] ?? 0) + 1;
    }
    final total = claims.length;
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MigoColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MigoColors.dividerLight),
      ),
      child: Column(
        children: entries.map((e) {
          final pct = (e.value / total);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _label(e.key),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${e.value} (${(pct * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: MigoColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor:
                        MigoColors.primary.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation(
                      MigoColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _label(String source) {
    switch (source) {
      case 'home':
        return 'Home';
      case 'search':
        return 'Search';
      case 'map':
        return 'Map';
      case 'referral':
        return 'Referral';
      case 'creator':
        return 'Creator';
      case 'whatsapp_share':
        return 'WhatsApp';
      case 'group_deal':
        return 'Group deal';
      default:
        return source;
    }
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MigoColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MigoColors.dividerLight),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: MigoColors.textSecondaryLight),
        ),
      ),
    );
  }
}