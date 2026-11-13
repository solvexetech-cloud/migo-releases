// migo-business/lib/features/scan/scan_qr_screen.dart
// FIXED - Handles PIN for both demand_claims and old claims
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
  late MobileScannerController _scannerController;

  bool _loading = false;
  bool _cameraMode = false;
  bool _scannedOnce = false;
  String? _successMsg;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _redeem(String code) async {
    final trimmed = code.trim();
    debugPrint('ðŸ” Scanned QR / PIN: $trimmed');

    if (trimmed.isEmpty) {
      setState(() => _errorMsg = 'Please provide a code.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
      _successMsg = null;
    });

    try {
      // ðŸ†• Extract PIN from QR format or direct PIN
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

      // ðŸ†• Try to find in demand_claims first (new system)
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

        // Mark as redeemed
        await claimDoc.reference.update({
          'status': 'redeemed',
          'redeemedAt': FieldValue.serverTimestamp(),
        });

        // Mark demand group as fulfilled
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
          _successMsg =
              'Demand Claim Redeemed!\nOrder: ${claimData['groupTitle']}\nPIN: ${claimData['pin']}';
          _codeController.clear();
          _cameraMode = false;
        });
        return;
      }

      // ðŸ†• Try old claims collection
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

  void _onDetect(BarcodeCapture capture) {
    if (_scannedOnce || _loading) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _scannedOnce = true);
    _redeem(raw);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _scannedOnce = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Scan & Redeem'),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _cameraMode = !_cameraMode;
                _errorMsg = null;
                _successMsg = null;
              });
            },
            icon: Icon(_cameraMode ? Icons.keyboard : Icons.qr_code_scanner),
          ),
        ],
      ),
      body: SafeArea(
        child: _cameraMode ? _buildScanner() : _buildManualEntry(),
      ),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
                errorBuilder: (context, error) => Center(
                  child: Text(
                    'Camera Error: ${error.errorCode}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF0C566), width: 3),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Point camera at customer's QR",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        if (_successMsg != null || _errorMsg != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _successMsg != null
                ? Colors.green.withValues(alpha: 0.12)
                : Colors.red.withValues(alpha: 0.12),
            child: Row(
              children: [
                Icon(
                  _successMsg != null ? Icons.check_circle : Icons.error,
                  color: _successMsg != null ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _successMsg ?? _errorMsg ?? '',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildManualEntry() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter code manually',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Type the 6-digit pickup code.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeController,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: const InputDecoration(
              labelText: 'Claim / Pickup code',
              hintText: 'e.g. 123456',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.qr_code_2),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : () => _redeem(_codeController.text),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Redeem'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _cameraMode = true),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR with camera'),
            ),
          ),
          if (_successMsg != null) ...[
            const SizedBox(height: 20),
            _ResultBanner(success: true, message: _successMsg!),
          ],
          if (_errorMsg != null) ...[
            const SizedBox(height: 20),
            _ResultBanner(success: false, message: _errorMsg!),
          ],
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.success, required this.message});
  final bool success;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = success ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(success ? Icons.check_circle : Icons.error, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}