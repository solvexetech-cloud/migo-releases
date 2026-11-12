// migo-business/lib/features/demands/demand_bids_screen.dart
// UPDATED - Responsive Bid Dialog (Stacked on mobile, two columns on PC)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/localization/app_localizations.dart';
import 'demand_redemption_screen.dart';
import 'my_bids_screen.dart';

class DemandBidsScreen extends StatelessWidget {
  final String? groupId;
  final Map<String, dynamic>? groupData;

  const DemandBidsScreen({super.key, this.groupId, this.groupData});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final t = AppLocalizations.of(context)!;
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(groupData != null ? (isAr ? 'تفاصيل الطلب' : 'Demand Details') : (isAr ? 'طلبات المجتمع' : 'Community Demands')),
              actions: [
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('businesses').where('ownerUid', isEqualTo: FirebaseAuth.instance.currentUser?.uid).limit(1).get(),
                  builder: (context, snap) {
                    if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox();
                    final businessId = snap.data!.docs.first.id;
                    return IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      tooltip: isAr ? 'استرداد الطلب' : 'Redeem Order',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => DemandRedemptionScreen(businessId: businessId)));
                      },
                    );
                  },
                ),
              ],
              backgroundColor: const Color(0xFF0F2B5B),
              foregroundColor: Colors.white,
            ),
            body: groupData != null
                ? _buildSingleDemandView(context, groupData!, isAr, t)
                : _buildEmptyState(isAr),
          ),
        );
      },
    );
  }

  Widget _buildSingleDemandView(BuildContext context, Map<String, dynamic> data, bool isAr, AppLocalizations t) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('demand_bids')
          .where('groupId', isEqualTo: groupId)
          .where('businessId', isEqualTo: uid)
          .limit(1)
          .get(),
      builder: (context, snap) {
        final hasBid = snap.hasData && snap.data!.docs.isNotEmpty;
        final title = data['title'] ?? '';
        final memberCount = data['memberCount'] ?? 0;
        final totalQuantity = data['totalQuantity'] ?? 0;
        final minPrice = data['minPrice'] ?? data['minTargetPrice'] ?? 0.0;
        final maxPrice = data['maxPrice'] ?? data['maxTargetPrice'] ?? 0.0;
        final category = data['category'] ?? '';
        final threshold = data['threshold'] ?? 3;
        final isBulk = threshold == 1;
        final brand = data['brand'] ?? '';
        final urgency = data['urgency'] ?? 'Flexible';
        final budgetType = data['budgetType'] ?? 'Flexible';

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
                      Expanded(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text('$minPrice - $maxPrice QAR', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.people, isBulk ? (isAr ? 'طلب بالجملة' : 'Bulk Order') : '$memberCount ${t.get('people_want_this')}', highlight: !isBulk),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.category, category),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.inventory, '${t.get('total_quantity')}: $totalQuantity'),
                        const SizedBox(height: 8),
                        if (brand.isNotEmpty) _buildDetailRow(Icons.branding_watermark, '${isAr ? 'العلامة التجارية' : 'Brand'}: $brand'),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.timer, '${isAr ? 'الاستعجال' : 'Urgency'}: $urgency'),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.account_balance_wallet, '${isAr ? 'نوع الميزانية' : 'Budget'}: $budgetType'),
                        const SizedBox(height: 8),
                        if (data['deliveryDate'] != null)
                          _buildDetailRow(
                            Icons.calendar_today, 
                            '${isAr ? 'تاريخ التسليم' : 'Delivery Date'}: ${(data['deliveryDate'] as Timestamp).toDate().day}/${(data['deliveryDate'] as Timestamp).toDate().month}/${(data['deliveryDate'] as Timestamp).toDate().year}', 
                            highlight: true
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasBid ? Colors.grey : const Color(0xFF0F2B5B), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: hasBid 
                          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBidsScreen())) 
                          : () => _showBidDialog(context, groupId!, data, isAr, isBulk, category),
                      icon: Icon(hasBid ? Icons.check_circle : Icons.gavel, color: Colors.white),
                      label: Text(
                        hasBid ? (isAr ? 'لقد قدمت عرضاً بالفعل (تعديل)' : 'Bid Already Placed (Edit)') : t.get('place_bid'), 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: highlight ? Colors.blue.shade700 : Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: highlight ? Colors.blue.shade700 : Colors.grey.shade800, fontSize: 13, fontWeight: highlight ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }

  Widget _buildEmptyState(bool isAr) {
    return Center(child: Text(isAr ? 'لم يتم تحديد طلب' : 'No demand selected', style: const TextStyle(fontSize: 16, color: Colors.grey)));
  }

  void _showBidDialog(BuildContext context, String groupId, Map<String, dynamic> groupData, bool isAr, bool isBulk, String category) {
    final t = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final priceController = TextEditingController();
    final authController = TextEditingController(text: 'Original');
    final fulfillmentController = TextEditingController(text: 'Store Pickup');
    final minCommitmentsController = TextEditingController(text: isBulk ? '1' : '${groupData['totalQuantity'] ?? 1}');
    bool isSubmitting = false;

    String? _categorySpecificValue;
    List<String> categoryOptions = [];
    
    if (category.toLowerCase() == 'electronics') {
      categoryOptions = ['Original', 'Master Copy', 'Refurbished'];
    } else if (category.toLowerCase() == 'fashion') {
      categoryOptions = ['Branded', 'Local', 'Custom'];
    } else if (category.toLowerCase() == 'food') {
      categoryOptions = ['Freshly Prepared', 'Ready to Eat'];
    } else if (category.toLowerCase() == 'home') {
      categoryOptions = ['New', 'Used'];
    } else {
      categoryOptions = ['Standard'];
    }
    _categorySpecificValue = categoryOptions.first;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final double unitPrice = double.tryParse(priceController.text) ?? 0.0;
            final int qty = groupData['totalQuantity'] ?? 0;
            final double totalPrice = unitPrice * qty;
            final isWide = MediaQuery.of(context).size.width >= 700;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(t.get('place_bid'), style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: isWide ? 600 : double.maxFinite,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: isWide 
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 1, child: _buildCustomerInfo(groupData, isAr)),
                            const VerticalDivider(width: 24),
                            Expanded(flex: 1, child: _buildShopBidInputs(priceController, authController, fulfillmentController, minCommitmentsController, categoryOptions, _categorySpecificValue!, isAr, isBulk, setState, unitPrice, qty, totalPrice, category)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildCustomerInfo(groupData, isAr),
                            const Divider(height: 32),
                            _buildShopBidInputs(priceController, authController, fulfillmentController, minCommitmentsController, categoryOptions, _categorySpecificValue!, isAr, isBulk, setState, unitPrice, qty, totalPrice, category),
                          ],
                        ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext), child: Text(isAr ? 'إلغاء' : 'Cancel')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F2B5B)),
                  onPressed: isSubmitting ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    setState(() => isSubmitting = true);
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      final businessId = user?.uid ?? 'unknown_biz';
                      final businessDoc = await FirebaseFirestore.instance.collection('businesses').where('ownerUid', isEqualTo: user?.uid).limit(1).get();
                      final businessName = businessDoc.docs.isNotEmpty ? (businessDoc.docs.first.data()['name'] ?? 'Shop') : 'Shop';
                      double currentTrustScore = 50.0;
                      if (businessDoc.docs.isNotEmpty) currentTrustScore = (businessDoc.docs.first.data()['trustScore'] as num?)?.toDouble() ?? 50.0;

                      await FirebaseFirestore.instance.collection('demand_bids').add({
                        'groupId': groupId,
                        'groupTitle': groupData['title'] ?? 'Unknown', 
                        'deliveryDate': groupData['deliveryDate'], 
                        'businessId': businessId,
                        'businessName': businessName,
                        'offerPrice': double.parse(priceController.text),
                        'totalPrice': totalPrice,
                        'quantity': qty,
                        'categorySpecific': _categorySpecificValue,
                        'fulfillmentType': fulfillmentController.text,
                        'businessTrustScore': currentTrustScore,
                        'minCommitments': isBulk ? 1 : int.parse(minCommitmentsController.text),
                        'status': 'pending',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      await FirebaseFirestore.instance.collection('demand_groups').doc(groupId).update({'status': 'bidding'});

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'تم إرسال العرض للمراجعة!' : 'Bid sent for approval!'), backgroundColor: Colors.green));
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    } finally {
                      if (dialogContext.mounted) setState(() => isSubmitting = false);
                    }
                  },
                  child: isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isAr ? 'إرسال' : 'Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🆕 Customer Info (Left side)
  Widget _buildCustomerInfo(Map<String, dynamic> groupData, bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
        const SizedBox(height: 8),
        _buildInfoRow('Product', groupData['title'] ?? ''),
        _buildInfoRow('Quantity', '${groupData['totalQuantity']}'),
        _buildInfoRow('Price Range', 'QAR ${groupData['minPrice']} - ${groupData['maxPrice']}'),
        _buildInfoRow('Brand', groupData['brand'] ?? 'Any'),
        _buildInfoRow('Urgency', groupData['urgency'] ?? 'Flexible'),
        _buildInfoRow('Budget', groupData['budgetType'] ?? 'Flexible'),
        _buildInfoRow('Delivery', groupData['deliveryDate'] != null 
            ? '${(groupData['deliveryDate'] as Timestamp).toDate().day}/${(groupData['deliveryDate'] as Timestamp).toDate().month}/${(groupData['deliveryDate'] as Timestamp).toDate().year}' 
            : 'Flexible'),
      ],
    );
  }

  // 🆕 Shop Inputs (Right side)
  Widget _buildShopBidInputs(
    TextEditingController priceController,
    TextEditingController authController,
    TextEditingController fulfillmentController,
    TextEditingController minCommitmentsController,
    List<String> categoryOptions,
    String selectedCategoryOption,
    bool isAr,
    bool isBulk,
    StateSetter setState,
    double unitPrice,
    int qty,
    double totalPrice,
    String category,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Bid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
        const SizedBox(height: 8),
        TextFormField(
          controller: priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: isAr ? 'سعر الوحدة (QAR)' : 'Unit Price (QAR)', 
            border: const OutlineInputBorder(), 
            prefixIcon: const Icon(Icons.attach_money)
          ),
          validator: (val) => (val == null || double.tryParse(val) == null) ? 'Invalid number' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: selectedCategoryOption,
          decoration: InputDecoration(labelText: isAr ? 'التفاصيل' : 'Details', border: const OutlineInputBorder()),
          items: categoryOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
          onChanged: (val) {},
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: fulfillmentController.text,
          decoration: InputDecoration(labelText: isAr ? 'طريقة التسليم' : 'Fulfillment', border: const OutlineInputBorder()),
          items: [
            DropdownMenuItem(value: 'Store Pickup', child: Text(isAr ? 'استلام من المتجر' : 'Store Pickup')),
            DropdownMenuItem(value: 'Home Delivery', child: Text(isAr ? 'توصيل للمنزل' : 'Home Delivery')),
          ],
          onChanged: (val) => fulfillmentController.text = val ?? 'Store Pickup',
        ),
        if (!isBulk) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: minCommitmentsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: isAr ? 'الحد الأدنى للمشتري' : 'Min Buyers', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.people)),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Required';
              final num = int.tryParse(val);
              if (num == null || num < 1) return 'Min 1';
              return null;
            },
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isAr ? 'سعر الوحدة:' : 'Unit Price:', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('QAR ${unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isAr ? 'الكمية:' : 'Quantity:', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isAr ? 'الإجمالي:' : 'Total:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                  Text('QAR ${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.blue)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}