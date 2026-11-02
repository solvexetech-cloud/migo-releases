import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/localization/locale_provider.dart';

class DemandRedemptionScreen extends StatefulWidget {
  final String businessId;

  const DemandRedemptionScreen({super.key, required this.businessId});

  @override
  State<DemandRedemptionScreen> createState() => _DemandRedemptionScreenState();
}

class _DemandRedemptionScreenState extends State<DemandRedemptionScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _isScanning = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  // --- 1. REDEEM VIA PIN (For Home Delivery) ---
  Future<void> _redeemWithPin(bool isAr) async {
    if (_pinController.text.trim().length != 6) {
      setState(() => _errorMessage = isAr ? 'يجب أن يكون الرمز 6 أرقام' : 'PIN must be 6 digits');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Find the claim with this PIN and business ID
      final snapshot = await FirebaseFirestore.instance
          .collection('demand_claims')
          .where('redemptionPin', isEqualTo: _pinController.text.trim())
          .where('businessId', isEqualTo: widget.businessId)
          .where('status', isEqualTo: 'locked')
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() => _errorMessage = isAr ? 'رمز PIN غير صالح أو تم استخدامه' : 'Invalid or already used PIN');
        return;
      }

      // Mark as redeemed
      await snapshot.docs.first.reference.update({
        'status': 'redeemed',
        'redeemedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showSuccessDialog(isAr, 'PIN');
    } catch (e) {
      setState(() => _errorMessage = isAr ? 'حدث خطأ. حاول مرة أخرى.' : 'Error. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. REDEEM VIA QR (For Store Pickup) ---
  Future<void> _handleQrScan(String qrData, bool isAr) async {
    setState(() => _isLoading = true);

    try {
      // The QR data is formatted as: MIGO_DEMAND_{demandId}_{userId}_{pin}
      // We can just search for the qrData exact string
      final snapshot = await FirebaseFirestore.instance
          .collection('demand_claims')
          .where('qrData', isEqualTo: qrData)
          .where('businessId', isEqualTo: widget.businessId)
          .where('status', isEqualTo: 'locked')
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _errorMessage = isAr ? 'رمز QR غير صالح أو تم استخدامه' : 'Invalid or already used QR code';
          _isScanning = false;
        });
        return;
      }

      await snapshot.docs.first.reference.update({
        'status': 'redeemed',
        'redeemedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _isScanning = false);
      _showSuccessDialog(isAr, 'QR');
    } catch (e) {
      setState(() {
        _errorMessage = isAr ? 'حدث خطأ أثناء مسح الرمز' : 'Error scanning QR';
        _isScanning = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(bool isAr, String method) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(isAr ? 'تم الاسترداد!' : 'Redeemed!'),
          ],
        ),
        content: Text(
          isAr 
            ? 'تم استرداد العرض بنجاح عبر $method.' 
            : 'Deal successfully redeemed via $method.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to dashboard
            },
            child: Text(isAr ? 'حسناً' : 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(isAr ? 'استرداد الطلب' : 'Redeem Demand'),
              backgroundColor: const Color(0xFF0F2B5B),
              foregroundColor: Colors.white,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- Section 1: QR Scanner ---
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.qr_code_scanner, size: 48, color: Color(0xFF0F2B5B)),
                          const SizedBox(height: 12),
                          Text(
                            isAr ? 'استلام من المتجر (QR)' : 'Store Pickup (QR)',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAr ? 'امسح رمز QR الخاص بالعميل لاسترداد الطلب.' : 'Scan the customer\'s QR code to redeem.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          if (_isScanning)
                            SizedBox(
                              height: 250,
                              child: MobileScanner(
                                onDetect: (capture) {
                                  final barcodes = capture.barcodes;
                                  if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                                    _handleQrScan(barcodes.first.rawValue!, isAr);
                                  }
                                },
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F2B5B),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 45),
                              ),
                              onPressed: () => setState(() => _isScanning = true),
                              icon: const Icon(Icons.camera_alt),
                              label: Text(isAr ? 'بدء المسح' : 'Start Scanning'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(isAr ? 'أو' : 'OR', style: const TextStyle(color: Colors.grey)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Section 2: PIN Entry ---
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.pin, size: 48, color: Colors.amber),
                          const SizedBox(height: 12),
                          Text(
                            isAr ? 'توصيل للمنزل (PIN)' : 'Home Delivery (PIN)',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAr ? 'أدخل رمز PIN المكون من 6 أرقام من العميل.' : 'Enter the 6-digit PIN from the customer.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                            maxLength: 6,
                            decoration: InputDecoration(
                              hintText: '000000',
                              counterText: '',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 45),
                            ),
                            onPressed: _isLoading ? null : () => _redeemWithPin(isAr),
                            child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(isAr ? 'تأكيد الرمز' : 'Confirm PIN'),
                          ),
                        ],
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
}