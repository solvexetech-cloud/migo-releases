import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';


class ScanQrScreen extends StatefulWidget {
  final String businessId;
  const ScanQrScreen({super.key, required this.businessId});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final _codeController = TextEditingController();
  final _scannerController = MobileScannerController();
  
  bool _loading = false;
  bool _cameraMode = false;
  String? _successMsg;
  String? _errorMsg;

  @override
  void dispose() {
    _codeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _redeem(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _successMsg = null;
      _errorMsg = null;
    });

    try {
      String? pin;
      String? claimId;

      if (trimmed.startsWith('MIGO-CLAIM-')) {
        final parts = trimmed.split('-');
        if (parts.length >= 5) {
          claimId = parts[2];
          pin = parts[4];
        }
      } else if (trimmed.startsWith('MIGO-OFFER-')) {
        final parts = trimmed.split('-');
        if (parts.length >= 3) {
          pin = parts[2];
        }
      } else if (RegExp(r'^\d{6}$').hasMatch(trimmed)) {
        pin = trimmed;
      }

      if (pin == null) {
        throw Exception('Invalid QR format. Please scan a valid claim.');
      }

      // Try demand_claims first
      QuerySnapshot demandQuery = await FirebaseFirestore.instance
          .collection('demand_claims')
          .where('pin', isEqualTo: pin)
          .where('businessId', isEqualTo: widget.businessId)
          .where('status', isEqualTo: 'locked')
          .limit(1)
          .get();

      if (demandQuery.docs.isNotEmpty) {
        final claimDoc = demandQuery.docs.first;
        final claimData = claimDoc.data() as Map<String, dynamic>;

        await claimDoc.reference.update({
          'status': 'redeemed',
          'redeemedAt': FieldValue.serverTimestamp(),
        });

        final groupId = claimData['groupId'];
        if (groupId != null) {
          await FirebaseFirestore.instance
              .collection('demand_groups')
              .doc(groupId)
              .update({
            'status': 'fulfilled',
            'redeemedAt': FieldValue.serverTimestamp(),
          });
        }

        if (!mounted) return;
        setState(() {
          _successMsg = 'Demand Claim Redeemed!\nPIN: ${claimData['pin']}';
          _codeController.clear();
          _cameraMode = false;
        });
        return;
      }

      // Try old claims collection
      QuerySnapshot oldQuery = await FirebaseFirestore.instance
          .collection('claims')
          .where('pickupCode', isEqualTo: pin)
          .where('businessId', isEqualTo: widget.businessId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (oldQuery.docs.isNotEmpty) {
        await oldQuery.docs.first.reference.update({
          'status': 'redeemed',
          'redeemedAt': FieldValue.serverTimestamp(),
        });
        // 🆕 Trust Score System
        final claimData = oldQuery.docs.first.data() as Map<String, dynamic>;
        final bizId = claimData['businessId'];
        if (bizId != null) {
          await FirebaseFirestore.instance.collection('businesses').doc(bizId).update({
            'trustScore': FieldValue.increment(1),
          });
        }

        if (!mounted) return;
        setState(() {
          _successMsg = 'Offer Claim Redeemed Successfully!\nCode: $pin';
          _codeController.clear();
          _cameraMode = false;
        });
        return;
      }

      throw Exception('Invalid or already redeemed claim.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // à´ªàµà´°àµ€à´®à´¿à´¯à´‚ à´¬à´¾à´•àµà´•àµà´—àµà´°àµ—à´£àµà´Ÿàµ
      appBar: AppBar(
        title: const Text(
          'Scan & Redeem',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF0F172A), // à´¡à´¾àµ¼à´•àµà´•àµ à´¬àµà´²àµ‚
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _cameraMode ? _buildCameraMode() : _buildManualMode(),
    );
  }

  Widget _buildManualMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter code manually',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Type the 6-digit pickup code to redeem the offer.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Input Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18, fontFamily: 'monospace', letterSpacing: 2),
              decoration: InputDecoration(
                hintText: 'Claim / Pickup code',
                hintStyle: const TextStyle(fontSize: 16, letterSpacing: 0),
                prefixIcon: const Icon(Icons.qr_code_2, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Redeem Button
          SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : () => _redeem(_codeController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A), // à´¡à´¾àµ¼à´•àµà´•àµ à´¬àµà´²àµ‚
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Redeem Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 24),

          // QR Scan Button
          SizedBox(
            height: 56,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _cameraMode = true;
                  _successMsg = null;
                  _errorMsg = null;
                });
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0F172A), width: 2),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, size: 20),
                  SizedBox(width: 8),
                  Text('Scan QR with Camera', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Messages
          if (_successMsg != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDEF7EC), // à´²àµˆà´±àµà´±àµ à´—àµà´°àµ€àµ»
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF31C48D), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF03543F), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _successMsg!,
                      style: const TextStyle(color: Color(0xFF03543F), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

          if (_errorMsg != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E8), // à´²àµˆà´±àµà´±àµ à´±àµ†à´¡àµ
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF98080), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: const Color(0xFF9B1C1C), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(color: Color(0xFF9B1C1C), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraMode() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _redeem(barcode.rawValue!);
                _scannerController.stop();
                break;
              }
            }
          },
        ),
        // Overlay with semi-transparent background
        Container(
          color: Colors.black.withValues(alpha: 0.4),
        ),
        // Scan window
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.amber, width: 3), // à´—àµ‹àµ¾à´¡àµ» à´¬àµ‹àµ¼à´¡àµ¼
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        // Instruction Text
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Point camera at customer\'s QR',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        // Close button
        Positioned(
          top: 20,
          right: 20,
          child: IconButton(
            onPressed: () {
              _scannerController.stop();
              setState(() => _cameraMode = false);
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}