import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HowToUseDialog extends StatefulWidget {
  final VoidCallback onClose;
  const HowToUseDialog({super.key, required this.onClose});

  @override
  State<HowToUseDialog> createState() => _HowToUseDialogState();
}

class _HowToUseDialogState extends State<HowToUseDialog> {
  bool _dontShowAgain = false;

  Future<void> _handleClose() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('never_show_how_to_use', true);
    }
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // മുകളിലെ ബാർ (Close ബട്ടണിനൊപ്പം)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'How to Use MIGO',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _handleClose,
                ),
              ],
            ),
            const Divider(),
            // കണ്ടന്റ് ഭാഗം (സ്ക്രോൾ ചെയ്യാൻ പറ്റുന്നത്)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStep(Icons.search, 'Discover Offers', 'Browse nearby shops, offers, and community demands.'),
                    _buildStep(Icons.qr_code_scanner, 'Scan & Redeem', 'Scan QR codes at the shop to redeem your offers.'),
                    _buildStep(Icons.stars, 'Earn Coins', 'Earn MIGO coins for every redemption and share them with friends.'),
                    _buildStep(Icons.group, 'Community Demands', 'Create a demand for a product you want. When enough people join, shops will bid for you!'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // "Never show again" ചെക്ക്ബോക്സ്
            Row(
              children: [
                Checkbox(
                  value: _dontShowAgain,
                  onChanged: (val) => setState(() => _dontShowAgain = val ?? false),
                ),
                const Expanded(
                  child: Text('Never show this again', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Remind Me Later ബട്ടൺ
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.onClose,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Remind me later'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}