import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/demand_model.dart';
import '../../models/demand_bid_model.dart';
import '../../services/demand_service.dart';
import 'claim_details_screen.dart';

class BidsComparisonScreen extends StatelessWidget {
  final DemandModel demand;

  const BidsComparisonScreen({super.key, required this.demand});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';
        
        final title = demand.title[isAr ? 'ar' : 'en'] ?? demand.title['en'] ?? '';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(isAr ? 'مقارنة العروض' : 'Compare Bids'),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: DemandService().getBidsStream(demand.id),
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
                        Text(
                          isAr ? 'لا توجد عروض معتمدة بعد' : 'No approved bids yet',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final bids = snapshot.data!.docs
                    .map((doc) => DemandBidModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bids.length,
                  itemBuilder: (context, index) {
                    final bid = bids[index];
                    return _BidCard(bid: bid, demand: demand, isAr: isAr);
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
  final DemandBidModel bid;
  final DemandModel demand;
  final bool isAr;

  const _BidCard({required this.bid, required this.demand, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final businessName = bid.businessName[isAr ? 'ar' : 'en'] ?? bid.businessName['en'] ?? 'Shop';
    final isHomeDelivery = bid.fulfillmentType == 'Home Delivery';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Shop Name & Trust Score
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: MigoColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.store, color: MigoColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        businessName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${bid.businessTrustScore.toStringAsFixed(1)} / 100',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${demand.currency} ${bid.offerPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: MigoColors.primary),
                    ),
                    if (bid.offerPrice < demand.targetPrice)
                      Text(
                        isAr ? 'أقل من السعر المستهدف' : 'Below target',
                        style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
            
            const Divider(height: 24),

            // 2. Details (Authenticity & Fulfillment)
            Row(
              children: [
                Expanded(
                  child: _InfoTag(
                    icon: bid.authenticity == 'Original' ? Icons.verified : Icons.content_copy,
                    label: bid.authenticity == 'Original' 
                        ? (isAr ? 'أصلي' : 'Original') 
                        : (isAr ? 'نسخة ماستر' : 'Master Copy'),
                    color: bid.authenticity == 'Original' ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoTag(
                    icon: isHomeDelivery ? Icons.delivery_dining : Icons.storefront,
                    label: isHomeDelivery 
                        ? (isAr ? 'توصيل للمنزل' : 'Home Delivery') 
                        : (isAr ? 'استلام من المتجر' : 'Store Pickup'),
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 🆕 Minimum Buyers Required
            Row(
              children: [
                const Icon(Icons.people_alt_outlined, size: 16, color: Colors.purple),
                const SizedBox(width: 6),
                Text(
                  isAr 
                    ? 'الحد الأدنى: ${bid.minCommitments} مشترين' 
                    : 'Min Buyers Required: ${bid.minCommitments}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3. Action Button
            SizedBox(
              width: double.infinity,
              height: 45,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: MigoColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClaimDetailsScreen(demand: demand, bid: bid),
                    ),
                  );
                },
                child: Text(
                  isAr ? 'أنا مهتم (احجز)' : 'I am Interested (Commit)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Small reusable widget for tags
class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoTag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}