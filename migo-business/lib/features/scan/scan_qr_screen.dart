import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/migo_gradients.dart';
import '../../core/theme/migo_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/claim_service.dart';
import '../../services/reservation_service.dart';

/// PHASE I ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â Scan QR (Business App)
/// Scans: CLM_ (claim) | RSV_ (reservation) | 6-digit pickup code
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
    _initScanner();
  }

  void _initScanner() {
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

  // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
  // HELPER: Add Coins to Customer
  // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
  Future<void> _addCoinsToCustomer(String uid, int amount) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      await userRef.update({
        'coins': FieldValue.increment(amount),
      });
      
      // Add transaction log (optional but good for tracking)
      await FirebaseFirestore.instance.collection('coin_transactions').add({
        'uid': uid,
        'amount': amount,
        'type': 'redeem',
        'description': 'Redeemed reservation at business',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('ÃƒÆ’Ã‚Â¢Ãƒâ€¦Ã¢â‚¬Å“ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ Added $amount coins to $uid');
    } catch (e) {
      debugPrint('ÃƒÆ’Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒâ€¦Ã¢â‚¬â„¢ Failed to add coins: $e');
    }
  }

  Future<void> _redeem(String code) async {
    final trimmed = code.trim();
    debugPrint('ÃƒÆ’Ã‚Â°Ãƒâ€¦Ã‚Â¸ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒâ€šÃ‚Âµ Scan called: $trimmed');

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

      // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ MIGO_PAY_ QR (Pay with Coins) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
      if (trimmed.startsWith('MIGO_PAY_')) {
        final paymentId = trimmed.substring(9); // 'MIGO_PAY_' ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â´ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¿ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚ÂµÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¿ ID ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€¦Ã‚Â½ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€¦Ã‚Â¸ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¨ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¨ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚Â
        
        // ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¡ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¯ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â®ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¨ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â±ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚Â ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚ÂµÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¿ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚ÂµÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â°ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚Â¾ ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â«ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¯ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚Â¼ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¡ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¸ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¿ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚Â½ ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¨ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¿ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¨ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¨ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚Â ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€¦Ã‚Â½ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€¦Ã‚Â¸ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¨ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¨ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚Â
        final paymentDoc = await FirebaseFirestore.instance
            .collection('coin_payments')
            .doc(paymentId)
            .get();

        if (!paymentDoc.exists) {
          throw Exception('Invalid or expired payment QR');
        }

        final data = paymentDoc.data()!;
        if (data['status'] != 'pending') {
          throw Exception('This payment is already ${data['status']}');
        }

        final customerUid = data['userId'] as String;
        final coinsUsed = (data['coinsUsed'] as num).toInt();
        final billAmount = (data['billAmount'] as num).toDouble();
        final currency = data['currency'] as String? ?? 'QAR';

        // ÃƒÆ’Ã‚Â°Ãƒâ€¦Ã‚Â¸ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¹ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¯ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¿ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚Â» ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¡ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¯ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â®ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¨ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â±ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚Â ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¸ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â±ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â±ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚Â ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¯ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¯ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¨ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â´Ãƒâ€šÃ‚Â¨ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚ÂµÃƒâ€šÃ‚Â
        await ClaimService.instance.acceptCoinPayment(
          paymentId: paymentId,
          customerUid: customerUid,
          coinsUsed: coinsUsed,
          businessId: widget.businessId,
        );

        if (!mounted) return;
        setState(() {
          _successMsg = 'ÃƒÆ’Ã‚Â¢Ãƒâ€¦Ã¢â‚¬Å“ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ Payment Accepted!\nBill: $currency ${billAmount.toStringAsFixed(2)}\nCoins Used: $coinsUsed';
          _codeController.clear();
          _cameraMode = false;
        });
        return;
      }
      // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ RSV_ QR ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
      if (trimmed.startsWith('RSV_')) {
        final qrCode = trimmed.substring(4);
        final res = await ReservationService.instance.validateQRCode(
          qrCode,
          widget.businessId,
        );
        if (res == null) {
          throw Exception('Invalid or expired reservation');
        }
        
        await ReservationService.instance.markPickedUp(res.id);
        
        // ÃƒÆ’Ã‚Â¢Ãƒâ€¦Ã¢â‚¬Å“ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ FIX: Add +5 coins to customer
        await _addCoinsToCustomer(res.userUid, 5);
        
        if (!mounted) return;
        setState(() {
          _successMsg = 'Reservation pickup confirmed! +5 coins sent.ÃƒÆ’Ã‚Â¢Ãƒâ€¦Ã¢â‚¬Å“ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦';
          _codeController.clear();
          _cameraMode = false;
        });
        return;
      }

      // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ 6-digit pickup code ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
      if (RegExp(r'^\d{6}$').hasMatch(trimmed)) {
        final res = await ReservationService.instance
            .validateByPickupCode(trimmed, widget.businessId);
        if (res == null) {
          throw Exception('Invalid or expired pickup code');
        }
        
        await ReservationService.instance.markPickedUp(res.id);
        
        // ÃƒÆ’Ã‚Â¢Ãƒâ€¦Ã¢â‚¬Å“ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ FIX: Add +5 coins to customer
        await _addCoinsToCustomer(res.userUid, 5);
        
        if (!mounted) return;
        setState(() {
          _successMsg = 'Reservation pickup confirmed! +5 coins sent.ÃƒÆ’Ã‚Â¢Ãƒâ€¦Ã¢â‚¬Å“ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦';
          _codeController.clear();
          _cameraMode = false;
        });
        return;
      }

      // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ CLM_ QR ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
      final claimId = trimmed.startsWith('CLM_')
          ? trimmed.substring(4)
          : trimmed;
      await ClaimService.instance.redeemClaim(
        claimId: claimId,
        businessId: widget.businessId,
      );
      if (!mounted) return;
            setState(() {
        _successMsg = 'Claim redeemed successfully! Coins sent to customer.';
        _codeController.clear();
        _cameraMode = false;
      });
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
        title: const Text('Scan & Redeem'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _cameraMode = !_cameraMode;
                _errorMsg = null;
                _successMsg = null;
              });
            },
            icon: Icon(
              _cameraMode ? Icons.keyboard : Icons.qr_code_scanner,
            ),
            tooltip: _cameraMode ? 'Enter code' : 'Scan QR',
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
                                errorBuilder: (context, error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Camera Error: ${error.errorCode}',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.errorDetails?.message ?? '',
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: MigoColors.accent,
                    width: 3,
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_2,
                        color: Colors.white,
                        size: 18,
                      ),
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
                ? MigoColors.success.withValues(alpha: 0.12)
                : MigoColors.error.withValues(alpha: 0.12),
            child: Row(
              children: [
                Icon(
                  _successMsg != null
                      ? Icons.check_circle
                      : Icons.error,
                  color: _successMsg != null
                      ? MigoColors.success
                      : MigoColors.error,
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Paste the code or type the 6-digit pickup code. Tap the camera icon to scan.',
            style: TextStyle(
              fontSize: 13,
              color: MigoColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeController,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: const InputDecoration(
              labelText: 'Claim / Pickup code',
              hintText: 'e.g. CLM_xxxx or 123456',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.qr_code_2),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _loading
                  ? null
                  : () => _redeem(_codeController.text),
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
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: MigoGradients.softBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: MigoColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  color: MigoColors.primary,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Faster: use the camera icon in the top-right to scan the customer's QR directly.",
                    style: TextStyle(
                      fontSize: 12,
                      color: MigoColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    final color = success ? MigoColors.success : MigoColors.error;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}