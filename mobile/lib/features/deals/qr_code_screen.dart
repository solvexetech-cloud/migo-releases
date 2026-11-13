import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';

class QrCodeScreen extends StatelessWidget {
  final String claimId;
  final String offerTitle;
  final String businessName;

  const QrCodeScreen({
    super.key,
    required this.claimId,
    required this.offerTitle,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: MigoColors.backgroundLight,
            appBar: AppBar(
              title: Text(isAr ? 'عرض رمز QR' : 'Show QR Code'),
              backgroundColor: MigoColors.primary,
              foregroundColor: Colors.white,
            ),
            body: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('claims')
                  .doc(claimId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(
                    child: Text(isAr ? 'لم يتم العثور على المطالبة' : 'Claim not found'),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final status = data['status'] as String?;
                
                // 🆕 pickupCode എടുക്കുന്നു (PIN)
                final pickupCode = data['pickupCode'] as String? ?? claimId;

                if (status == 'redeemed') {
                  return _buildRedeemedSuccess(isAr);
                }

                return _buildQrView(isAr, pickupCode);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildQrView(bool isAr, String pickupCode) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: MigoColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAr ? 'أظهر هذا في المتجر' : 'SHOW THIS AT THE SHOP',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: MigoColors.primary,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // QR Code Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black12, width: 2),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: QrImageView(
                data: 'MIGO-OFFER-$pickupCode', // 🆕 ശരിയായ QR ഫോർമാറ്റ്
                version: QrVersions.auto,
                size: 240.0,
                backgroundColor: Colors.white,
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 32),
            Text(
              isAr ? 'أو استخدم رمز الاستلام' : 'Or use pickup code',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),

            // Pickup Code (PIN)
            SelectableText(
              pickupCode, // 🆕 PIN കാണിക്കുന്നു
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    offerTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    businessName,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedeemedSuccess(bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: MigoColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: MigoColors.success,
                      size: 100,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              isAr ? 'تم الاسترداد بنجاح!' : 'Successfully Redeemed!',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: MigoColors.success,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isAr
                  ? 'شكراً لاستخدامك ميجو. نتمنى لك يوماً سعيداً!'
                  : 'Thank you for using MIGO. Have a great day!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: MigoColors.textSecondaryLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                offerTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: MigoColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}