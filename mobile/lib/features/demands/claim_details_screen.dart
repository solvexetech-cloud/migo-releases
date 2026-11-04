import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/demand_model.dart';
import '../../models/demand_bid_model.dart';
import '../../models/demand_claim_model.dart';
import '../../services/demand_service.dart';
import 'claim_ticket_screen.dart';

class ClaimDetailsScreen extends StatefulWidget {
  final DemandModel demand;
  final DemandBidModel bid;

  const ClaimDetailsScreen({super.key, required this.demand, required this.bid});

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
    if (widget.bid.fulfillmentType == 'Home Delivery') {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _isLoading = true);

    final result = await DemandService().commitToOffer(
      demandId: widget.demand.id,
      bidId: widget.bid.id,
      businessId: widget.bid.businessId,
      businessName: widget.bid.businessName,
      finalPrice: widget.bid.offerPrice,
      fulfillmentType: widget.bid.fulfillmentType,
      minCommitments: widget.bid.minCommitments,
      deliveryAddress: widget.bid.fulfillmentType == 'Home Delivery' ? _addressController.text.trim() : null,
      deliveryPhone: widget.bid.fulfillmentType == 'Home Delivery' ? _phoneController.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == 'locked') {
      final snapshot = await FirebaseFirestore.instance
          .collection('demand_claims')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty && mounted) {
        final claimData = DemandClaimModel.fromMap(
          snapshot.docs.first.id,
          snapshot.docs.first.data() as Map<String, dynamic>,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ClaimTicketScreen(demand: widget.demand, claim: claimData),
          ),
        );
      }
    } else if (result == 'waiting') {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تمت إضافتك إلى قائمة الانتظار. نحتاج المزيد من المشترين!' : 'Added to waitlist. Need more buyers to unlock the offer!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else if (result == 'already_committed') {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'أنت بالفعل في قائمة الانتظار لهذا العرض.' : 'You are already in the waitlist for this offer.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'حدث خطأ. حاول مرة أخرى.' : 'Error. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';
        final isHomeDelivery = widget.bid.fulfillmentType == 'Home Delivery';
        final businessName = widget.bid.businessName[isAr ? 'ar' : 'en'] ?? widget.bid.businessName['en'] ?? 'Shop';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(isAr ? 'تأكيد الطلب' : 'Confirm Order'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded( // 🆕 Overflow പരിഹരിക്കാൻ
                                child: Text(
                                  isAr ? 'المتجر' : 'Shop',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  businessName,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  isAr ? 'طريقة التسليم' : 'Fulfillment',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  isHomeDelivery 
                                      ? (isAr ? 'توصيل للمنزل' : 'Home Delivery') 
                                      : (isAr ? 'استلام من المتجر' : 'Store Pickup'),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  isAr ? 'السعر النهائي' : 'Final Price',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${widget.demand.currency} ${widget.bid.offerPrice.toStringAsFixed(0)}',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: MigoColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Delivery Details (Only if Home Delivery)
                    if (isHomeDelivery) ...[
                      Text(
                        isAr ? 'معلومات التوصيل' : 'Delivery Information',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: isAr ? 'العنوان الكامل' : 'Full Address',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                        maxLines: 2,
                        validator: (val) => val == null || val.isEmpty ? (isAr ? 'مطلوب' : 'Required') : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: isAr ? 'رقم الهاتف' : 'Phone Number',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return isAr ? 'مطلوب' : 'Required';
                          if (val.length < 8) return isAr ? 'رقم غير صالح' : 'Invalid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Terms Note
                    Text(
                      isAr 
                        ? 'ملاحظة: الدفع نقداً عند الاستلام. أنت مسؤول عن استلام المنتج.'
                        : 'Note: Cash on delivery/pickup. You are responsible for receiving the product.',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 24),

                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: MigoColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : () => _lockDeal(isAr),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                isAr ? 'تأكيد وحجز' : 'Confirm & Lock Deal',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
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
}