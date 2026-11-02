import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/demand_model.dart';
import '../../models/demand_claim_model.dart';

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
            appBar: AppBar(
              title: Text(isAr ? 'تذكرة الاسترداد' : 'Redemption Ticket'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Order Info Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MigoColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          businessName,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${demand.currency} ${claim.finalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: MigoColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // QR Code Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isAr ? 'امسح الرمز للاسترداد' : 'Scan QR to Redeem',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        QrImageView(
                          data: claim.qrData,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 6-Digit PIN Section (Only for Home Delivery)
                  if (isDelivery) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade700, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isAr ? 'رمز PIN للتوصيل' : 'Delivery PIN',
                            style: TextStyle(fontSize: 14, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            claim.redemptionPin,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAr ? 'شارك هذا الرمز مع مندوب التوصيل بعد استلام المنتج.' : 'Share this PIN with the delivery staff after receiving the product.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'التعليمات:' : 'Instructions:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildInstruction(
                          isDelivery 
                              ? (isAr ? '1. انتظر حتى يصل مندوب التوصيل.' : '1. Wait for the delivery staff.')
                              : (isAr ? '1. اذهب إلى المتجر.' : '1. Go to the shop.'),
                        ),
                        _buildInstruction(
                          isDelivery 
                              ? (isAr ? '2. ادفع نقداً عند استلام المنتج.' : '2. Pay cash upon receiving the product.')
                              : (isAr ? '2. ادفع نقداً في المتجر.' : '2. Pay cash at the shop.'),
                        ),
                        _buildInstruction(
                          isDelivery
                              ? (isAr ? '3. شارك رمز PIN مع المندوب.' : '3. Share the PIN with the staff.')
                              : (isAr ? '3. اعرض رمز QR للمسح.' : '3. Show the QR code for scanning.'),
                        ),
                      ],
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

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
    );
  }
}