import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/demand_model.dart';
import '../../models/demand_claim_model.dart';
import '../complaints/report_complaint_screen.dart';

class ClaimTicketScreen extends StatelessWidget {
  final DemandModel demand;
  final DemandClaimModel claim;

  const ClaimTicketScreen({super.key, required this.demand, required this.claim});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';
        final title = demand.title[isAr ? 'ar' : 'en'] ?? demand.title['en'] ?? '';
        final businessName = claim.businessName[isAr ? 'ar' : 'en'] ?? claim.businessName['en'] ?? 'Shop';
        final isDelivery = claim.fulfillmentType == 'Home Delivery';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              title: Text(isAr ? 'ØªØ°ÙƒØ±Ø© Ø§Ù„Ø§Ø³ØªØ±Ø¯Ø§Ø¯' : 'Redemption Ticket', style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: Colors.black,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Hero Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF1E3A8A).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          businessName,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${demand.currency} ${claim.finalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // QR Code Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.qr_code_scanner, color: MigoColors.primary, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              isAr ? 'Ø§Ù…Ø³Ø­ Ø§Ù„Ø±Ù…Ø² Ù„Ù„Ø§Ø³ØªØ±Ø¯Ø§Ø¯' : 'Scan QR to Redeem',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: QrImageView(
                            data: claim.qrData,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Manual Pickup Code
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            children: [
                              Text(
                                isAr ? 'Ø£Ùˆ Ø§Ø³ØªØ®Ø¯Ù… Ø±Ù…Ø² Ø§Ù„Ø§Ø³ØªÙ„Ø§Ù…' : 'Or use pickup code',
                                style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                claim.redemptionPin,
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 6, color: Colors.blue.shade900),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 6-Digit PIN Section (Only for Home Delivery)
                  if (isDelivery) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.shade700, width: 2),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delivery_dining, color: Colors.amber.shade900, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                isAr ? 'Ø±Ù…Ø² PIN Ù„Ù„ØªÙˆØµÙŠÙ„' : 'Delivery PIN',
                                style: TextStyle(fontSize: 16, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            claim.redemptionPin,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isAr ? 'Ø´Ø§Ø±Ùƒ Ù‡Ø°Ø§ Ø§Ù„Ø±Ù…Ø² Ù…Ø¹ Ù…Ù†Ø¯ÙˆØ¨ Ø§Ù„ØªÙˆØµÙŠÙ„ Ø¨Ø¹Ø¯ Ø§Ø³ØªÙ„Ø§Ù… Ø§Ù„Ù…Ù†ØªØ¬.' : 'Share this PIN with the delivery staff after receiving the product.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'Ø§Ù„ØªØ¹Ù„ÙŠÙ…Ø§Øª:' : 'Instructions:',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 12),
                        _buildInstruction(
                          Icons.store,
                          isDelivery 
                              ? (isAr ? 'Ø§Ù†ØªØ¸Ø± Ø­ØªÙ‰ ÙŠØµÙ„ Ù…Ù†Ø¯ÙˆØ¨ Ø§Ù„ØªÙˆØµÙŠÙ„.' : 'Wait for the delivery staff.')
                              : (isAr ? 'Ø§Ø°Ù‡Ø¨ Ø¥Ù„Ù‰ Ø§Ù„Ù…ØªØ¬Ø±.' : 'Go to the shop.'),
                        ),
                        _buildInstruction(
                          Icons.payments,
                          isDelivery 
                              ? (isAr ? 'Ø§Ø¯ÙØ¹ Ù†Ù‚Ø¯Ø§Ù‹ Ø¹Ù†Ø¯ Ø§Ø³ØªÙ„Ø§Ù… Ø§Ù„Ù…Ù†ØªØ¬.' : 'Pay cash upon receiving the product.')
                              : (isAr ? 'Ø§Ø¯ÙØ¹ Ù†Ù‚Ø¯Ø§Ù‹ ÙÙŠ Ø§Ù„Ù…ØªØ¬Ø±.' : 'Pay cash at the shop.'),
                        ),
                        _buildInstruction(
                          Icons.qr_code,
                          isDelivery
                              ? (isAr ? 'Ø´Ø§Ø±Ùƒ Ø±Ù…Ø² PIN Ù…Ø¹ Ø§Ù„Ù…Ù†Ø¯ÙˆØ¨.' : 'Share the PIN with the staff.')
                              : (isAr ? 'Ø§Ø¹Ø±Ø¶ Ø±Ù…Ø² QR Ù„Ù„Ù…Ø³Ø­.' : 'Show the QR code for scanning.'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Report Problem Link
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportComplaintScreen(
                              orderId: claim.id,
                              businessName: businessName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.report_problem, size: 16),
                      label: Text(isAr ? 'Ø§Ù„Ø¥Ø¨Ù„Ø§Øº Ø¹Ù† Ù…Ø´ÙƒÙ„Ø©' : 'Having Issues?', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}