import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/demand_model.dart';
import '../../core/localization/locale_provider.dart';
import '../../services/demand_service.dart';
import 'demand_redemption_screen.dart';
import 'my_bids_screen.dart';

class DemandBidsScreen extends StatelessWidget {
  final DemandModel? demand;

  const DemandBidsScreen({super.key, this.demand});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(demand != null ? (isAr ? 'تفاصيل الطلب' : 'Demand Details') : (isAr ? 'طلبات المجتمع' : 'Community Demands')),
              actions: [
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('businesses')
                      .where('ownerUid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .limit(1)
                      .get(),
                  builder: (context, snap) {
                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return const SizedBox();
                    }
                    final businessId = snap.data!.docs.first.id;

                    return IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      tooltip: isAr ? 'استرداد الطلب' : 'Redeem Order',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DemandRedemptionScreen(businessId: businessId),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
              backgroundColor: const Color(0xFF0F2B5B),
              foregroundColor: Colors.white,
            ),
            body: demand != null
                ? _buildSingleDemandView(context, demand!, isAr)
                : _buildDemandsList(context, isAr),
          ),
        );
      },
    );
  }

  Widget _buildSingleDemandView(BuildContext context, DemandModel demand, bool isAr) {
    final title = demand.title[isAr ? 'ar' : 'en'] ?? demand.title['en'] ?? '';
    final desc = demand.description[isAr ? 'ar' : 'en'] ?? demand.description['en'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${demand.currency} ${demand.targetPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
                    ),
                  ),
                ],
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.people, '${demand.currentCount} ${isAr ? 'أشخاص' : 'people'} joined'),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.category, demand.category),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2B5B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    _showBidDialog(context, demand, isAr);
                  },
                  icon: const Icon(Icons.gavel, color: Colors.white),
                  label: Text(isAr ? 'تقديم عرض' : 'Place Bid', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDemandsList(BuildContext context, bool isAr) {
    return Column(
      children: [
        // 🆕 പേജിന്റെ മുകളിൽ വലിയ My Bids ബട്ടൺ
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F2B5B),
                side: const BorderSide(color: Color(0xFF0F2B5B), width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBidsScreen()),
                );
              },
              icon: const Icon(Icons.receipt_long, size: 24),
              label: Text(
                isAr ? 'عرض عروضي (My Bids)' : 'View My Bids',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
        
        // താഴെ ഡിമാൻഡ് ലിസ്റ്റ്
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: DemandService().getDemandsStream(status: 'threshold_reached'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    isAr ? 'لا توجد طلبات نشطة حالياً' : 'No active demands currently',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              final demands = snapshot.data!.docs
                  .map((doc) => DemandModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                  .toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: demands.length,
                itemBuilder: (context, index) {
                  final d = demands[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      title: Text(d.title['en'] ?? ''),
                      subtitle: Text('${d.currentCount} / ${d.minRequiredCount} joined'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DemandBidsScreen(demand: d)),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showBidDialog(BuildContext context, DemandModel demand, bool isAr) {
    // ... (Bid dialog code remains same)
    final formKey = GlobalKey<FormState>();
    final priceController = TextEditingController();
    final authController = TextEditingController(text: 'Original');
    final fulfillmentController = TextEditingController(text: 'Store Pickup');
    final minCommitmentsController = TextEditingController(text: '20');
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isAr ? 'تقديم عرض' : 'Place a Bid'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: isAr ? 'سعرك (QAR)' : 'Your Price (QAR)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          if (double.tryParse(val) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: authController.text,
                        decoration: InputDecoration(
                          labelText: isAr ? 'الأصالة' : 'Authenticity',
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(value: 'Original', child: Text(isAr ? 'أصلي' : 'Original')),
                          DropdownMenuItem(value: 'Master Copy', child: Text(isAr ? 'نسخة ماستر' : 'Master Copy')),
                        ],
                        onChanged: (val) {
                          if (val != null) authController.text = val;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: fulfillmentController.text,
                        decoration: InputDecoration(
                          labelText: isAr ? 'طريقة التسليم' : 'Fulfillment',
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(value: 'Store Pickup', child: Text(isAr ? 'استلام من المتجر' : 'Store Pickup')),
                          DropdownMenuItem(value: 'Home Delivery', child: Text(isAr ? 'توصيل للمنزل' : 'Home Delivery')),
                        ],
                        onChanged: (val) {
                          if (val != null) fulfillmentController.text = val;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: minCommitmentsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isAr ? 'الحد الأدنى للمشتري' : 'Minimum Buyers Required',
                          helperText: isAr ? 'لن يتم تنشيط العرض حتى يوافق هذا العدد.' : 'Offer activates only if this many people commit.',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.people),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          final num = int.tryParse(val);
                          if (num == null || num < 1) return 'Min 1';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: Text(isAr ? 'إلغاء' : 'Cancel'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => isSubmitting = true);

                          final user = FirebaseAuth.instance.currentUser;
                          final businessId = user?.uid ?? 'unknown_biz';
                          final businessName = {'en': user?.displayName ?? 'My Business', 'ar': user?.displayName ?? 'My Business'};

                          // 🆕 ബിസിനസിന്റെ യഥാർത്ഥ ട്രസ്റ്റ് സ്കോർ എടുക്കുക
                          final businessDoc = await FirebaseFirestore.instance
                              .collection('businesses')
                              .where('ownerUid', isEqualTo: user?.uid)
                              .limit(1)
                              .get();
                          
                          double currentTrustScore = 50.0;
                          if (businessDoc.docs.isNotEmpty) {
                            currentTrustScore = (businessDoc.docs.first.data()['trustScore'] as num?)?.toDouble() ?? 50.0;
                          }

                          final success = await DemandService().placeBid(
                            demandId: demand.id,
                            businessId: businessId,
                            businessName: businessName,
                            offerPrice: double.parse(priceController.text),
                            authenticity: authController.text,
                            fulfillmentType: fulfillmentController.text,
                            businessTrustScore: currentTrustScore,
                            minCommitments: int.parse(minCommitmentsController.text),
                          );

                          setState(() => isSubmitting = false);

                          if (!dialogContext.mounted) return;

                          if (success) {
                            Navigator.pop(dialogContext);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isAr ? 'تم إرسال العرض للمراجعة!' : 'Bid sent for approval!')),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isAr ? 'حدث خطأ.' : 'Error placing bid.')),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isAr ? 'إرسال' : 'Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}