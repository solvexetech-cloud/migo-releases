import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Show QR Code'),
        backgroundColor: MigoColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'SHOW THIS AT THE SHOP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              
              // QR Code Placeholder
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: MigoColors.dividerLight, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.qr_code_2, size: 200, color: MigoColors.primary),
              ),
              
              const SizedBox(height: 32),
              const Text(
                'Or use pickup code',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              
              // മുഴുവൻ ഐഡിയും ഇവിടെ കാണിക്കുന്നു
              SelectableText(
                claimId, 
                style: const TextStyle(
                  fontSize: 14, // ഫോണ്ട് സൈസ് കുറച്ചു
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
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
      ),
    );
  }
}