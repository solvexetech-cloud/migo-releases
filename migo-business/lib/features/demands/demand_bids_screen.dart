import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/demand_model.dart';
import '../../core/localization/locale_provider.dart'; 
import '../../services/demand_service.dart';
import 'demand_redemption_screen.dart';
import 'my_bids_screen.dart';

class DemandBidsScreen extends StatelessWidget {
  const DemandBidsScreen({super.key});

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
              title: Text(isAr ? 'طلبات المجتمع' : 'Community Demands'),
              // ✅ FIX: Using FutureBuilder to get the real businessId
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
                // 👇 ഇതാണ് പുതിയതായി ചേർക്കുന്നത് 👇
                IconButton(
                  icon: const Icon(Icons.receipt_long),
                  tooltip: isAr ? 'عروضي' : 'My Bids',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyBidsScreen()),
                    );
                  },
                ),
              ],
              backgroundColor: const Color(0xFF0F2B5B), // MIGO Business Blue
              foregroundColor: Colors.white,
            ),
            body: StreamBuilder<QuerySnapshot>(
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
                  padding: const EdgeInsets.all(16),
                  itemCount: demands.length,
                  itemBuilder: (context, index) {
                    final demand = demands[index];
                    final title = demand.title[isAr ? 'ar' : 'en'] ?? demand.title['en'] ?? '';
                    final desc = demand.description[isAr ? 'ar' : 'en'] ?? demand.description['en'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${demand.currency} ${demand.targetPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                            if (desc.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(desc, style: const TextStyle(color: Colors.grey)),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.people, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${demand.currentCount} / ${demand.requiredCount} ${isAr ? 'أشخاص' : 'people'}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const Spacer(),
                                Text(
                                  isAr ? 'الهدف: ${demand.targetPrice} QAR' : 'Target: ${demand.targetPrice} QAR',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F2B5B),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  _showBidDialog(context, demand, isAr);
                                },
                                icon: const Icon(Icons.gavel),
                                label: Text(isAr ? 'تقديم عرض' : 'Place Bid'),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  void _showBidDialog(BuildContext context, DemandModel demand, bool isAr) {
    final formKey = GlobalKey<FormState>();
    final priceController = TextEditingController();
    final authController = TextEditingController(text: 'Original');
    final fulfillmentController = TextEditingController(text: 'Store Pickup');
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
                  ],
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
                          
                          const double currentTrustScore = 50.0;

                          final success = await DemandService().placeBid(
                            demandId: demand.id,
                            businessId: businessId,
                            businessName: businessName,
                            offerPrice: double.parse(priceController.text),
                            authenticity: authController.text,
                            fulfillmentType: fulfillmentController.text,
                            businessTrustScore: currentTrustScore,
                          );

                                                                              setState(() => isSubmitting = false);

                          // ✅ FIX: Use dialogContext to check if the dialog is still open
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