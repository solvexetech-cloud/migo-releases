import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/localization/locale_provider.dart';

class DemandRedemptionScreen extends StatefulWidget {
  final String businessId; // à´²àµ‹à´—à´¿àµ» à´šàµ†à´¯àµà´¤ à´¬à´¿à´¸à´¿à´¨à´¸àµà´¸à´¿à´¨àµà´±àµ† UID

  const DemandRedemptionScreen({super.key, required this.businessId});

  @override
  State<DemandRedemptionScreen> createState() => _DemandRedemptionScreenState();
}

class _DemandRedemptionScreenState extends State<DemandRedemptionScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _isScanning = false;
  String? _errorMessage;
  String? _actualBusinessId;

  @override
  void initState() {
    super.initState();
    _fetchActualBusinessId();
  }

  Future<void> _fetchActualBusinessId() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('businesses')
          .where('ownerUid', isEqualTo: widget.businessId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() => _actualBusinessId = query.docs.first.id);
      }
    } catch (e) {
      debugPrint('Error fetching business ID: $e');
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  // --- 1. REDEEM VIA PIN ---
  Future<void> _redeemWithPin(bool isAr) async {
    if (_pinController.text.trim().length != 6) {
      setState(() => _errorMessage = isAr ? 'ÙŠØ¬Ø¨ Ø£Ù† ÙŠÙƒÙˆÙ† Ø§Ù„Ø±Ù…Ø² 6 Ø£Ø±Ù‚Ø§Ù…' : 'PIN must be 6 digits');
      return;
    }
    if (_actualBusinessId == null) {
      setState(() => _errorMessage = isAr ? 'Ù„Ù… ÙŠØªÙ… Ø§Ù„Ø¹Ø«ÙˆØ± Ø¹Ù„Ù‰ Ø§Ù„Ù…ØªØ¬Ø±' : 'Business not found');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('demand_claims')
          .where('redemptionPin', isEqualTo: _pinController.text.trim())
          .where('status', isEqualTo: 'locked')
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() => _errorMessage = isAr ? 'Ø±Ù…Ø² PIN ØºÙŠØ± ØµØ§Ù„Ø­ Ø£Ùˆ ØªÙ… Ø§Ø³ØªØ®Ø¯Ø§Ù…Ù‡' : 'Invalid or already used PIN');
        return;
      }

      // âœ… à´¯à´¥à´¾àµ¼à´¤àµà´¥ à´¡àµ‹à´•àµà´¯àµà´®àµ†à´¨àµà´±àµ à´±à´«à´±àµ»à´¸àµ à´‰à´ªà´¯àµ‹à´—à´¿à´šàµà´šàµ à´…à´ªàµà´¡àµ‡à´±àµà´±àµ à´šàµ†à´¯àµà´¯àµà´¨àµà´¨àµ
      await snapshot.docs.first.reference.update({
        'status': 'redeemed',
        'redeemedAt': FieldValue.serverTimestamp(),
        'businessId': FirebaseAuth.instance.currentUser?.uid, // à´²àµ‹à´—à´¿àµ» UID
        'redeemedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      if (!mounted) return;
      _showSuccessDialog(isAr, 'PIN');
    } catch (e) {
      setState(() => _errorMessage = isAr ? 'Ø­Ø¯Ø« Ø®Ø·Ø£. Ø­Ø§ÙˆÙ„ Ù…Ø±Ø© Ø£Ø®Ø±Ù‰.' : 'Error. Try again.');
      debugPrint('PIN Redeem Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. REDEEM VIA QR ---
  Future<void> _handleQrScan(String qrData, bool isAr) async {
    if (_isLoading) return; // à´‡à´°à´Ÿàµà´Ÿà´¿ à´¸àµà´•à´¾àµ» à´’à´´à´¿à´µà´¾à´•àµà´•à´¾àµ»

    setState(() {
      _isScanning = false;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // âœ… qrData à´‰à´ªà´¯àµ‹à´—à´¿à´šàµà´šàµ à´¡àµ‹à´•àµà´¯àµà´®àµ†à´¨àµà´±àµ à´•à´£àµà´Ÿàµ†à´¤àµà´¤àµà´¨àµà´¨àµ
      // QR ഡാറ്റ ഉപയോഗിച്ച് ഡോക്യുമെന്റ് കണ്ടെത്തുന്നു
      final snapshot = await FirebaseFirestore.instance
          .collection('demand_claims')
          .where('qrData', isEqualTo: qrData)
          .where('status', isEqualTo: 'locked')
          .get();
          
      // ഒരു പക്ഷേ qrData കണ്ടെത്തിയില്ലെങ്കിൽ, claimId നേരിട്ട് ഉപയോഗിച്ച് നോക്കുന്നു (ബാക്കപ്പ്)
      if (snapshot.docs.isEmpty) {
        final directSnap = await FirebaseFirestore.instance
            .collection('demand_claims')
            .doc(qrData)
            .get();
        if (directSnap.exists) {
           // ...
        }
      }

      if (snapshot.docs.isEmpty) {
        setState(() {
          _errorMessage = isAr ? 'Ø±Ù…Ø² QR ØºÙŠØ± ØµØ§Ù„Ø­ Ø£Ùˆ ØªÙ… Ø§Ø³ØªØ®Ø¯Ø§Ù…Ù‡' : 'Invalid or already used QR code';
        });
        return;
      }

      // âœ… à´¯à´¥à´¾àµ¼à´¤àµà´¥ à´¡àµ‹à´•àµà´¯àµà´®àµ†à´¨àµà´±àµ à´±à´«à´±àµ»à´¸àµ à´‰à´ªà´¯àµ‹à´—à´¿à´šàµà´šàµ à´…à´ªàµà´¡àµ‡à´±àµà´±àµ à´šàµ†à´¯àµà´¯àµà´¨àµà´¨àµ
      await snapshot.docs.first.reference.update({
        'status': 'redeemed',
        'redeemedAt': FieldValue.serverTimestamp(),
        'businessId': FirebaseAuth.instance.currentUser?.uid, // à´²àµ‹à´—à´¿àµ» UID
        'redeemedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      if (!mounted) return;
      _showSuccessDialog(isAr, 'QR');
    } catch (e) {
      setState(() {
        _errorMessage = isAr ? 'Ø­Ø¯Ø« Ø®Ø·Ø£ Ø£Ø«Ù†Ø§Ø¡ Ù…Ø³Ø­ Ø§Ù„Ø±Ù…Ø²' : 'Error scanning QR';
      });
      debugPrint('QR Redeem Error: $e');
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
            Text(isAr ? 'ØªÙ… Ø§Ù„Ø§Ø³ØªØ±Ø¯Ø§Ø¯!' : 'Redeemed!'),
          ],
        ),
        content: Text(
          isAr
            ? 'ØªÙ… Ø§Ø³ØªØ±Ø¯Ø§Ø¯ Ø§Ù„Ø¹Ø±Ø¶ Ø¨Ù†Ø¬Ø§Ø­ Ø¹Ø¨Ø± $method.'
            : 'Deal successfully redeemed via $method.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(isAr ? 'Ø­Ø³Ù†Ø§Ù‹' : 'OK'),
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
              title: Text(isAr ? 'Ø§Ø³ØªØ±Ø¯Ø§Ø¯ Ø§Ù„Ø·Ù„Ø¨' : 'Redeem Demand'),
              backgroundColor: const Color(0xFF0F2B5B),
              foregroundColor: Colors.white,
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
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
                            isAr ? 'Ø§Ø³ØªÙ„Ø§Ù… Ù…Ù† Ø§Ù„Ù…ØªØ¬Ø± (QR)' : 'Store Pickup (QR)',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAr ? 'Ø§Ù…Ø³Ø­ Ø±Ù…Ø² QR Ø§Ù„Ø®Ø§Øµ Ø¨Ø§Ù„Ø¹Ù…ÙŠÙ„ Ù„Ø§Ø³ØªØ±Ø¯Ø§Ø¯ Ø§Ù„Ø·Ù„Ø¨.' : 'Scan the customer\'s QR code to redeem.',
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
                              label: Text(isAr ? 'Ø¨Ø¯Ø¡ Ø§Ù„Ù…Ø³Ø­' : 'Start Scanning'),
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
                        child: Text(isAr ? 'Ø£Ùˆ' : 'OR', style: const TextStyle(color: Colors.grey)),
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
                            isAr ? 'Ø¥Ø¯Ø®Ø§Ù„ Ø±Ù…Ø² PIN ÙŠØ¯ÙˆÙŠØ§Ù‹' : 'Enter PIN Manually',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAr ? 'Ø£Ø¯Ø®Ù„ Ø§Ù„Ø±Ù…Ø² Ø§Ù„Ù…ÙƒÙˆÙ† Ù…Ù† 6 Ø£Ø±Ù‚Ø§Ù… Ù…Ù† Ø§Ù„Ø¹Ù…ÙŠÙ„.' : 'Enter the 6-digit code from the customer.',
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
                                : Text(isAr ? 'ØªØ£ÙƒÙŠØ¯ Ø§Ù„Ø±Ù…Ø²' : 'Confirm PIN'),
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