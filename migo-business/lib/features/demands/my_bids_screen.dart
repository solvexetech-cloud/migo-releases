import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/localization/locale_provider.dart';
import '../../models/demand_bid_model.dart';
import '../../services/demand_service.dart';

class MyBidsScreen extends StatelessWidget {
  const MyBidsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';
        final uid = FirebaseAuth.instance.currentUser?.uid;

        if (uid == null) {
          return Scaffold(
            body: Center(
              child: Text(isAr ? 'يرجى تسجيل الدخول' : 'Please sign in'),
            ),
          );
        }

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF6F3EE),
            appBar: AppBar(
              title: Text(
                isAr ? 'عروضي' : 'My Bids',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              backgroundColor: const Color(0xFF0F2B5B),
              foregroundColor: Colors.white,
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('demand_bids')
                  .where('businessId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final bids = snapshot.data?.docs ?? [];
                if (bids.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.gavel_outlined,
                          size: 80,
                          color: Colors.blue.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isAr
                              ? 'لم تقدم أي عروض بعد'
                              : 'No bids submitted yet',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bids.length,
                  itemBuilder: (context, i) {
                    final doc = bids[i];
                    final bid = DemandBidModel.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    );
                    return _BidCard(bid: bid, isAr: isAr);
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
  final bool isAr;

  const _BidCard({required this.bid, required this.isAr});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    switch (bid.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = isAr ? 'قيد المراجعة' : 'Under Review';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusText = isAr ? 'تمت الموافقة' : 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = isAr ? 'مرفوض' : 'Rejected';
        break;
      default:
        statusColor = Colors.grey;
        statusText = bid.status;
    }

    final canEdit = bid.status == 'pending' || bid.status == 'approved';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'QAR ${bid.offerPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F2B5B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                if (canEdit) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                    onPressed: () => _showEditBidDialog(context, bid, isAr),
                    tooltip: isAr ? 'تعديل العرض' : 'Edit Bid',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            Row(
              children: [
                _InfoChip(
                  icon: bid.authenticity == 'Original'
                      ? Icons.verified
                      : Icons.content_copy,
                  label: bid.authenticity == 'Original'
                      ? (isAr ? 'أصلي' : 'Original')
                      : (isAr ? 'نسخة ماستر' : 'Master Copy'),
                  color: bid.authenticity == 'Original'
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: bid.fulfillmentType == 'Home Delivery'
                      ? Icons.delivery_dining
                      : Icons.storefront,
                  label: bid.fulfillmentType == 'Home Delivery'
                      ? (isAr ? 'توصيل' : 'Delivery')
                      : (isAr ? 'استلام' : 'Pickup'),
                  color: Colors.blue,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${bid.businessTrustScore.toStringAsFixed(1)} / 100',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBidDialog(BuildContext context, DemandBidModel bid, bool isAr) {
    final formKey = GlobalKey<FormState>();
    final priceController = TextEditingController(
      text: bid.offerPrice.toString(),
    );
    final authController = TextEditingController(text: bid.authenticity);
    final fulfillmentController = TextEditingController(
      text: bid.fulfillmentType,
    );
    final minCommitmentsController = TextEditingController(
      text: bid.minCommitments.toString(),
    );
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isAr ? 'تعديل العرض' : 'Edit Bid'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: isAr ? 'سعرك (QAR)' : 'Your Price (QAR)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          if (double.tryParse(val) == null)
                            return 'Invalid number';
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
                          DropdownMenuItem(
                            value: 'Original',
                            child: Text(isAr ? 'أصلي' : 'Original'),
                          ),
                          DropdownMenuItem(
                            value: 'Master Copy',
                            child: Text(isAr ? 'نسخة ماستر' : 'Master Copy'),
                          ),
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
                          DropdownMenuItem(
                            value: 'Store Pickup',
                            child: Text(
                              isAr ? 'استلام من المتجر' : 'Store Pickup',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Home Delivery',
                            child: Text(
                              isAr ? 'توصيل للمنزل' : 'Home Delivery',
                            ),
                          ),
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
                          labelText: isAr
                              ? 'الحد الأدنى للمشترين'
                              : 'Minimum Buyers Required',
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
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(isAr ? 'إلغاء' : 'Cancel'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => isSubmitting = true);

                          final success = await DemandService().updateBid(
                            bidId: bid.id,
                            offerPrice: double.parse(priceController.text),
                            authenticity: authController.text,
                            fulfillmentType: fulfillmentController.text,
                            minCommitments: int.parse(
                              minCommitmentsController.text,
                            ),
                          );

                          setState(() => isSubmitting = false);

                          if (!dialogContext.mounted) return;

                          if (success) {
                            Navigator.pop(dialogContext);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isAr
                                        ? 'تم تحديث العرض بنجاح!'
                                        : 'Bid updated successfully!',
                                  ),
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isAr ? 'حدث خطأ.' : 'Error updating bid.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isAr ? 'تحديث' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
