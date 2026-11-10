// mobile/lib/features/demands/claim_ticket_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import '../complaints/report_complaint_screen.dart';

class ClaimTicketScreen extends StatelessWidget {
  final String groupId;
  final Map<String, dynamic> groupData;
  final Map<String, dynamic> bidData;
  final String claimId;
  final String claimCode;

  const ClaimTicketScreen({
    super.key,
    required this.groupId,
    required this.groupData,
    required this.bidData,
    required this.claimId,
    required this.claimCode,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';
        
        final title = groupData['title'] ?? '';
        
        final rawName = bidData['businessName'];
        final String businessName;
        if (rawName is Map) {
          businessName = rawName[isAr ? 'ar' : 'en'] ?? rawName['en'] ?? 'Shop';
        } else {
          businessName = rawName?.toString() ?? 'Shop';
        }
        
        final fulfillmentType = bidData['fulfillmentType'] ?? 'Store Pickup';
        final isDelivery = fulfillmentType == 'Home Delivery';
        final offerPrice = (bidData['offerPrice'] as num?)?.toDouble() ?? 0.0;

        final String qrData = 'MIGO-CLAIM-$claimId-$claimCode';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              title: Text(isAr ? 'تذكرة الاسترداد' : 'Redemption Ticket', style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: Colors.black,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text(businessName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                          child: Text('${offerPrice.toStringAsFixed(0)} QAR', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200, width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.qr_code_scanner, color: MigoColors.primary, size: 24),
                            const SizedBox(width: 8),
                            Text(isAr ? 'امسح الرمز للاسترداد' : 'Scan QR to Redeem', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                          child: QrImageView(data: qrData, version: QrVersions.auto, size: 200.0, backgroundColor: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade100)),
                          child: Column(
                            children: [
                              Text(isAr ? 'أو استخدم رمز الاستلام' : 'Or use pickup code', style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(claimCode, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 6, color: Colors.blue.shade900)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isAr ? 'التعليمات:' : 'Instructions:', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
                        const SizedBox(height: 12),
                        _buildInstruction(Icons.store, isDelivery ? (isAr ? 'انتظر حتى يصل مندوب التوصيل.' : 'Wait for the delivery staff.') : (isAr ? 'اذهب إلى المتجر.' : 'Go to the shop.')),
                        _buildInstruction(Icons.payments, isDelivery ? (isAr ? 'ادفع نقداً عند استلام المنتج.' : 'Pay cash upon receiving the product.') : (isAr ? 'ادفع نقداً في المتجر.' : 'Pay cash at the shop.')),
                        _buildInstruction(Icons.qr_code, isDelivery ? (isAr ? 'شارك رمز PIN مع المندوب.' : 'Share the PIN with the staff.') : (isAr ? 'اعرض رمز QR للمسح.' : 'Show the QR code for scanning.')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ReportComplaintScreen(orderId: claimId, businessName: businessName),
                        ));
                      },
                      icon: const Icon(Icons.report_problem, size: 16),
                      label: Text(isAr ? 'الإبلاغ عن مشكلة' : 'Having Issues?', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstruction(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: Icon(icon, size: 16, color: Colors.grey.shade700)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}