// mobile/lib/features/demands/bids_comparison_screen.dart
// FIXED - Removed duplicate 'shape' property
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import 'claim_details_screen.dart';

class BidsComparisonScreen extends StatelessWidget {
  final String groupId;
  final Map<String, dynamic> groupData;
  
  const BidsComparisonScreen({super.key, required this.groupId, required this.groupData});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';
        final title = groupData['title'] ?? '';
        final threshold = groupData['threshold'] ?? 3;
        final isBulk = threshold == 1;

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(isAr ? 'مقارنة العروض' : 'Compare Bids'),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('demand_bids')
                  .where('groupId', isEqualTo: groupId)
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.storefront_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(isAr ? 'لا توجد عروض بعد' : 'No bids yet', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final bids = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bids.length,
                  itemBuilder: (context, index) {
                    final bidData = bids[index].data() as Map<String, dynamic>;
                    return _BidCard(
                      bidId: bids[index].id,
                      bidData: bidData,
                      groupId: groupId,
                      groupData: groupData,
                      isAr: isAr,
                      isBulk: isBulk,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _BidCard extends StatelessWidget {
  final String bidId;
  final Map<String, dynamic> bidData;
  final String groupId;
  final Map<String, dynamic> groupData;
  final bool isAr;
  final bool isBulk;

  const _BidCard({
    required this.bidId,
    required this.bidData,
    required this.groupId,
    required this.groupData,
    required this.isAr,
    required this.isBulk,
  });

  @override
  Widget build(BuildContext context) {
    final rawName = bidData['businessName'];
    final String businessName;
    if (rawName is Map) {
      businessName = rawName[isAr ? 'ar' : 'en'] ?? rawName['en'] ?? 'Shop';
    } else {
      businessName = rawName?.toString() ?? 'Shop';
    }
        
    final isHomeDelivery = (bidData['fulfillmentType'] ?? '') == 'Home Delivery';
    final offerPrice = (bidData['offerPrice'] as num?)?.toDouble() ?? 0.0;
    final targetPrice = (groupData['minTargetPrice'] as num?)?.toDouble() ?? 0.0;
    final trustScore = (bidData['businessTrustScore'] as num?)?.toDouble() ?? 50.0;
    final authenticity = bidData['authenticity'] ?? 'Original';
    final minCommitments = bidData['minCommitments'] ?? 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: bidData['status'] == 'approved' ? Colors.green : (bidData['status'] == 'rejected' ? Colors.red : Colors.orange),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: MigoColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.store, color: MigoColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(businessName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('${trustScore.toStringAsFixed(1)} / 100', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${offerPrice.toStringAsFixed(0)} QAR', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: MigoColors.primary)),
                    if (offerPrice < targetPrice)
                      Text(isAr ? 'أقل من السعر المستهدف' : 'Below target', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _InfoTag(
                    icon: authenticity == 'Original' ? Icons.verified : Icons.content_copy,
                    label: authenticity == 'Original' ? (isAr ? 'أصلي' : 'Original') : (isAr ? 'نسخة ماستر' : 'Master Copy'),
                    color: authenticity == 'Original' ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoTag(
                    icon: isHomeDelivery ? Icons.delivery_dining : Icons.storefront,
                    label: isHomeDelivery ? (isAr ? 'توصيل' : 'Home Delivery') : (isAr ? 'استلام' : 'Store Pickup'),
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            
            if (!isBulk) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.people_alt_outlined, size: 16, color: Colors.purple),
                  const SizedBox(width: 6),
                  Text(isAr ? 'الحد الأدنى: $minCommitments مشترين' : 'Min Buyers Required: $minCommitments', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
                ],
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: MigoColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ClaimDetailsScreen(groupId: groupId, groupData: groupData, bidId: bidId, bidData: bidData),
                  ));
                },
                child: Text(isAr ? 'أنا مهتم (احجز)' : 'I am Interested (Commit)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  
  const _InfoTag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}