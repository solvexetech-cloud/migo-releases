// mobile/lib/features/demands/claim_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/migo_colors.dart';
import 'claim_ticket_screen.dart';

class ClaimDetailsScreen extends StatefulWidget {
  final String groupId;
  final Map<String, dynamic> groupData;
  final String bidId;
  final Map<String, dynamic> bidData;

  const ClaimDetailsScreen({
    super.key,
    required this.groupId,
    required this.groupData,
    required this.bidId,
    required this.bidData,
  });

  @override
  State<ClaimDetailsScreen> createState() => _ClaimDetailsScreenState();
}

class _ClaimDetailsScreenState extends State<ClaimDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _lockDeal(bool isAr) async {
    final fulfillmentType = widget.bidData['fulfillmentType'] ?? 'Store Pickup';
    final isHomeDelivery = fulfillmentType == 'Home Delivery';

    if (isHomeDelivery && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final String pin = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      final String claimId = FirebaseFirestore.instance.collection('demand_claims').doc().id;

      await FirebaseFirestore.instance.collection('demand_claims').doc(claimId).set({
        'groupId': widget.groupId,
        'bidId': widget.bidId,
        'userId': user.uid,
        'businessId': widget.bidData['businessId'],
        'businessName': widget.bidData['businessName'],
        'status': 'locked', 
        'deliveryAddress': isHomeDelivery ? _addressController.text.trim() : null,
        'deliveryPhone': isHomeDelivery ? _phoneController.text.trim() : null,
        'pin': pin,
        'qrData': 'MIGO-CLAIM-$claimId-$pin',
        'createdAt': FieldValue.serverTimestamp(),
        'groupTitle': widget.groupData['title'],
        'totalPrice': (widget.bidData['offerPrice'] as num) * (widget.groupData['totalQuantity'] as num),
      });

      await FirebaseFirestore.instance.collection('demand_groups').doc(widget.groupId).update({
        'status': 'fulfilled',
        'acceptedBidId': widget.bidId,
      });

      if (!mounted) return;
      
      // 🆕 Navigate to QR Ticket
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => ClaimTicketScreen(
          groupId: widget.groupId,
          groupData: widget.groupData,
          bidData: widget.bidData,
          claimId: claimId,
          claimCode: pin,
        ),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';
        final fulfillmentType = widget.bidData['fulfillmentType'] ?? 'Store Pickup';
        final isHomeDelivery = fulfillmentType == 'Home Delivery';
        
        final rawName = widget.bidData['businessName'];
        final String businessName = rawName is Map 
            ? (rawName[isAr ? 'ar' : 'en'] ?? rawName['en'] ?? 'Shop')
            : (rawName?.toString() ?? 'Shop');

        final offerPrice = (widget.bidData['offerPrice'] as num?)?.toDouble() ?? 0.0;

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(title: Text(isAr ? 'تأكيد الطلب' : 'Confirm Order')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        children: [
                          _buildRow(isAr ? 'المتجر' : 'Shop', businessName),
                          const Divider(),
                          _buildRow(isAr ? 'طريقة التسليم' : 'Fulfillment', isHomeDelivery ? (isAr ? 'توصيل' : 'Home Delivery') : (isAr ? 'استلام' : 'Store Pickup')),
                          const Divider(),
                          _buildRow(isAr ? 'السعر النهائي' : 'Final Price', '${offerPrice.toStringAsFixed(0)} QAR', isBold: true),
                        ],
                      ),
                    ),
                    if (isHomeDelivery) ...[
                      const SizedBox(height: 24),
                      Text(isAr ? 'معلومات التوصيل' : 'Delivery Information', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextFormField(controller: _addressController, decoration: InputDecoration(labelText: isAr ? 'العنوان' : 'Address', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.location_on)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                      const SizedBox(height: 12),
                      TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: isAr ? 'رقم الهاتف' : 'Phone', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.phone)), validator: (v) => v == null || v.length < 8 ? 'Invalid' : null),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: MigoColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: _isLoading ? null : () => _lockDeal(isAr),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(isAr ? 'تأكيد وحجز' : 'Confirm & Lock Deal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, fontSize: isBold ? 18 : 14, color: isBold ? MigoColors.primary : Colors.black87)),
      ],
    );
  }
}