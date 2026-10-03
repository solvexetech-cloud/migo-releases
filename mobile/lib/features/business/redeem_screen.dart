import 'package:flutter/material.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/business_model.dart';
import '../../services/firestore_service.dart';

class RedeemScreen extends StatefulWidget {
  const RedeemScreen({super.key, required this.business});
  final BusinessModel business;

  @override
  State<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends State<RedeemScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _successMsg;
  String? _errorMsg;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMsg = 'Please enter a claim code.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
      _successMsg = null;
    });

    try {
      await FirestoreService.instance.redeemClaim(
        claimId: code,
        businessId: widget.business.id,
      );
      if (!mounted) return;
      setState(() {
        _successMsg =
            'Claim redeemed successfully! +25 coins sent to customer.';
        _codeController.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redeem claim')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter claim code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ask the customer to show their QR code, or type the short code shown under it.',
                style: TextStyle(
                  fontSize: 13,
                  color: MigoColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _codeController,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  labelText: 'Claim code',
                  hintText: 'Paste the code here',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code_2),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _redeem,
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
              if (_successMsg != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: MigoColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: MigoColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: MigoColors.success,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _successMsg!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_errorMsg != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: MigoColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: MigoColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: MigoColors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}