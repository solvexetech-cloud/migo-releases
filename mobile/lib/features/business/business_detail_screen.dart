import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/migo_colors.dart';
import '../../core/theme/migo_gradients.dart';
import '../../models/business_model.dart';
import '../reviews/business_reviews_screen.dart';
import '../deals/offer_detail_screen.dart';
import '../../models/offer_model.dart';

class BusinessDetailScreen extends StatelessWidget {
  final String businessId;
  final String businessName;

  const BusinessDetailScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2B5B), // Dark Blue
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          businessName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('businesses')
            .doc(businessId)
            .get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Business not found'));
          }

          final business = BusinessModel.fromMap(
            snap.data!.id,
            snap.data!.data() as Map<String, dynamic>,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.storefront, size: 32, color: Color(0xFF0F2B5B)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  business.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  business.category,
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, size: 8, color: Colors.green),
                                SizedBox(width: 4),
                                Text('OPEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(icon: Icons.access_time, text: business.hoursLabel),
                      const SizedBox(height: 8),
                      _InfoRow(icon: Icons.location_on_outlined, text: '${business.addressLine}, ${business.city}'),
                      if ((business.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          business.description!,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Call & Map Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final url = Uri.parse('tel:${business.phone ?? ""}');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              },
                              icon: const Icon(Icons.call, size: 18),
                              label: const Text('Call'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE8F5E9),
                                foregroundColor: Colors.green[800],
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final query = Uri.encodeComponent('${business.name}, ${business.addressLine}, ${business.city}');
                                final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              },
                              icon: const Icon(Icons.map, size: 18),
                              label: const Text('Map'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE3F2FD),
                                foregroundColor: const Color(0xFF0F2B5B),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Offers Section
                const Text('Offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('offers')
                      .where('businessId', isEqualTo: businessId)
                      .where('status', isEqualTo: 'live') // ലൈവ് ആയ ഓഫറുകൾ മാത്രം എടുക്കുന്നു
                      .snapshots(),
                  builder: (context, offerSnap) {
                    if (offerSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    // 1. എല്ലാ ഓഫറുകളും എടുക്കുന്നു
                    final allOffers = offerSnap.data?.docs ?? [];
                    
                    // 2. കാലഹരണപ്പെട്ട ഓഫറുകളും (endDate കഴിഞ്ഞവ) ഒഴിവാക്കുന്നു
                    final activeOffers = allOffers.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final endDate = (data['endDate'] as Timestamp?)?.toDate();
                      
                      // endDate ഉണ്ടെങ്കിൽ, അത് ഇന്നത്തെ തീയതിക്ക് ശേഷം ഉള്ളതാണോ എന്ന് ചെക്ക് ചെയ്യുക
                      if (endDate != null && endDate.isBefore(DateTime.now())) {
                        return false; // കാലഹരണപ്പെട്ടത് ഒഴിവാക്കുക
                      }
                      
                      // സ്റ്റാറ്റസ് 'live' അല്ലെങ്കിൽ 'paused' അല്ലാത്തവ ഒഴിവാക്കുക (ബാക്ക്എൻഡ് സേഫ്റ്റിക്ക് വേണ്ടി)
                      final status = data['status'] as String? ?? '';
                      if (status != 'live' && status != 'paused') {
                         return false;
                      }

                      return true; // ബാക്കിയുള്ളവ കാണിക്കുക
                    }).toList();

                    if (activeOffers.isEmpty) {
                      return const Text('No active offers available.');
                    }
                    
                    return Column(
                      children: activeOffers.map((doc) {
                        final offer = OfferModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(offer.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('QAR ${offer.offerPrice}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => OfferDetailScreen(offer: offer),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Reviews Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('4.0', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(4, (index) => const Icon(Icons.star, size: 16, color: Colors.amber)),
                              ),
                              const Text('from verified MIGO customers', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BusinessReviewsScreen(
                                  businessId: business.id,
                                  businessName: business.name,
                                ),
                              ),
                            );
                          },
                          child: const Text('View All Reviews'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}