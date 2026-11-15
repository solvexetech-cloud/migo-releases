import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
              title: Text(isAr ? 'Ã˜Â¹Ã˜Â±Ã˜Â¶ Ã˜Â±Ã™â€¦Ã˜Â² QR' : 'Show QR Code'),
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
                    child: Text(isAr ? 'Ã™â€žÃ™â€¦ Ã™Å Ã˜ÂªÃ™â€¦ Ã˜Â§Ã™â€žÃ˜Â¹Ã˜Â«Ã™Ë†Ã˜Â± Ã˜Â¹Ã™â€žÃ™â€° Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â·Ã˜Â§Ã™â€žÃ˜Â¨Ã˜Â©' : 'Claim not found'),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final status = data['status'] as String?;
                
                // Ã°Å¸â€ â€¢ pickupCode Ã Â´Å½Ã Â´Å¸Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´Â¨Ã ÂµÂÃ Â´Â¨Ã ÂµÂ (PIN)
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
                isAr ? 'Ã˜Â£Ã˜Â¸Ã™â€¡Ã˜Â± Ã™â€¡Ã˜Â°Ã˜Â§ Ã™ÂÃ™Å  Ã˜Â§Ã™â€žÃ™â€¦Ã˜ÂªÃ˜Â¬Ã˜Â±' : 'SHOW THIS AT THE SHOP',
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
                data: 'MIGO-OFFER-$pickupCode', // Ã°Å¸â€ â€¢ Ã Â´Â¶Ã Â´Â°Ã Â´Â¿Ã Â´Â¯Ã Â´Â¾Ã Â´Â¯ QR Ã Â´Â«Ã Âµâ€¹Ã ÂµÂ¼Ã Â´Â®Ã Â´Â¾Ã Â´Â±Ã ÂµÂÃ Â´Â±Ã ÂµÂ
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
              isAr ? 'Ã˜Â£Ã™Ë† Ã˜Â§Ã˜Â³Ã˜ÂªÃ˜Â®Ã˜Â¯Ã™â€¦ Ã˜Â±Ã™â€¦Ã˜Â² Ã˜Â§Ã™â€žÃ˜Â§Ã˜Â³Ã˜ÂªÃ™â€žÃ˜Â§Ã™â€¦' : 'Or use pickup code',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),

            // Pickup Code (PIN)
            SelectableText(
              pickupCode, // Ã°Å¸â€ â€¢ PIN Ã Â´â€¢Ã Â´Â¾Ã Â´Â£Ã Â´Â¿Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´Â¨Ã ÂµÂÃ Â´Â¨Ã ÂµÂ
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
              isAr ? 'Ã˜ÂªÃ™â€¦ Ã˜Â§Ã™â€žÃ˜Â§Ã˜Â³Ã˜ÂªÃ˜Â±Ã˜Â¯Ã˜Â§Ã˜Â¯ Ã˜Â¨Ã™â€ Ã˜Â¬Ã˜Â§Ã˜Â­!' : 'Successfully Redeemed!',
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
                  ? 'Ã˜Â´Ã™Æ’Ã˜Â±Ã˜Â§Ã™â€¹ Ã™â€žÃ˜Â§Ã˜Â³Ã˜ÂªÃ˜Â®Ã˜Â¯Ã˜Â§Ã™â€¦Ã™Æ’ Ã™â€¦Ã™Å Ã˜Â¬Ã™Ë†. Ã™â€ Ã˜ÂªÃ™â€¦Ã™â€ Ã™â€° Ã™â€žÃ™Æ’ Ã™Å Ã™Ë†Ã™â€¦Ã˜Â§Ã™â€¹ Ã˜Â³Ã˜Â¹Ã™Å Ã˜Â¯Ã˜Â§Ã™â€¹!'
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
class _CounterScannerScreen extends StatefulWidget {
  final String claimId;
  final bool isAr;
  const _CounterScannerScreen({required this.claimId, required this.isAr});

  @override
  State<_CounterScannerScreen> createState() => _CounterScannerScreenState();
}

class _CounterScannerScreenState extends State<_CounterScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _loading = false;

  Future<void> _redeem(String token) async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      // Find counter by token
      final counterSnap = await FirebaseFirestore.instance
          .collection('branch_counters')
          .where('token', isEqualTo: token)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (counterSnap.docs.isEmpty) {
        throw Exception('Invalid or expired counter QR.');
      }

      final counterData = counterSnap.docs.first.data();
      final shopId = counterData['businessId'];

      // Get claim
      final claimSnap = await FirebaseFirestore.instance.collection('claims').doc(widget.claimId).get();
      if (!claimSnap.exists) throw Exception('Claim not found.');
      
      final claimData = claimSnap.data()!;
      if (claimData['status'] != 'active') throw Exception('Claim is not active.');
      if (claimData['businessId'] != shopId) throw Exception('Wrong shop! This claim belongs to another business.');

      // Update claim
      await FirebaseFirestore.instance.collection('claims').doc(widget.claimId).update({
        'status': 'redeemed',
        'redeemedAt': FieldValue.serverTimestamp(),
        'redeemedBy': shopId,
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAr ? 'Ø§Ù…Ø³Ø­ Ø±Ù…Ø² Ø§Ù„ÙƒØ§Ø´ÙŠØ±' : 'Scan Cashier QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && barcode.rawValue!.startsWith('MIGO-COUNTER-')) {
                  final token = barcode.rawValue!.replaceFirst('MIGO-COUNTER-', '');
                  _controller.stop();
                  _redeem(token);
                  break;
                }
              }
            },
          ),
          if (_loading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(30)),
                child: Text(
                  widget.isAr ? 'ÙˆØ¬Ù‡ Ø§Ù„ÙƒØ§Ù…ÙŠØ±Ø§ Ù†Ø­Ùˆ Ø±Ù…Ø² Ø§Ù„ÙƒØ§Ø´ÙŠØ±' : 'Point at the cashier QR code',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}