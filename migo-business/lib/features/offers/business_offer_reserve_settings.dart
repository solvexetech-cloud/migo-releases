// MIGO Reserve - Business Offer Reserve Settings Screen
// Allows business owner to enable/configure reservation on an offer.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BusinessOfferReserveSettingsScreen extends StatefulWidget {
  final String offerId;
  final String businessId;

  const BusinessOfferReserveSettingsScreen({
    super.key,
    required this.offerId,
    required this.businessId,
  });

  @override
  State<BusinessOfferReserveSettingsScreen> createState() =>
      _BusinessOfferReserveSettingsScreenState();
}

class _BusinessOfferReserveSettingsScreenState
    extends State<BusinessOfferReserveSettingsScreen> {
  bool _loading = true;
  bool _saving = false;

  // Form state
  bool _reserveEnabled = false;
  int _totalSlots = 20;
  int _holdHours = 6;
  bool _tokenRequired = false;
  int _maxPerCustomer = 1;

  static const List<int> _slotOptions = [10, 20, 50, -1];
  static const List<int> _holdHourOptions = [1, 2, 3, 6, 12, 24];
  static const List<int> _maxPerCustomerOptions = [1, 2, 3, 5, 0];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();

      if (!doc.exists) {
        _showSnack('Offer not found', isError: true);
        if (mounted) Navigator.pop(context);
        return;
      }

      final data = doc.data() ?? {};
      final reserve = data['reserve'] as Map<String, dynamic>? ?? {};

      setState(() {
        _reserveEnabled = reserve['enabled'] as bool? ?? false;
        _totalSlots = reserve['totalSlots'] as int? ?? 20;
        _holdHours = reserve['holdHours'] as int? ?? 6;
        _tokenRequired = reserve['tokenRequired'] as bool? ?? false;
        _maxPerCustomer = reserve['maxPerCustomer'] as int? ?? 1;
        _loading = false;
      });
    } catch (e) {
      _showSnack('Failed to load settings: $e', isError: true);
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({
        'reserve': {
          'enabled': _reserveEnabled,
          'totalSlots': _totalSlots,
          'holdHours': _holdHours,
          'tokenRequired': _tokenRequired,
          'maxPerCustomer': _maxPerCustomer,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSnack('Settings saved successfully');
    } catch (e) {
      _showSnack('Save failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  String _slotLabel(int value) {
    if (value == -1) return 'Unlimited';
    return '$value slots';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserve Settings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.deepPurple.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MIGO Reserve',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enable guaranteed reservations for this offer. '
                          'Customers can book a slot and pick up without waiting.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Enable toggle
                  SwitchListTile(
                    title: const Text(
                      'Enable Reserve',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle:
                        const Text('Allow customers to book this offer'),
                    value: _reserveEnabled,
                    activeThumbColor: Colors.deepPurple,
                    onChanged: (v) =>
                        setState(() => _reserveEnabled = v),
                  ),

                  const Divider(height: 32),

                  if (_reserveEnabled) ...[
                    const Text(
                      'Total Slots',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _slotOptions.map((option) {
                        final selected = _totalSlots == option;
                        return ChoiceChip(
                          label: Text(_slotLabel(option)),
                          selected: selected,
                          selectedColor: Colors.deepPurple.shade100,
                          onSelected: (_) =>
                              setState(() => _totalSlots = option),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Hold Duration (hours)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How long a booking is held before expiry',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _holdHourOptions.map((option) {
                        final selected = _holdHours == option;
                        return ChoiceChip(
                          label: Text('${option}h'),
                          selected: selected,
                          selectedColor: Colors.deepPurple.shade100,
                          onSelected: (_) =>
                              setState(() => _holdHours = option),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    SwitchListTile(
                      title: const Text(
                        'Token Required',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Require a 6-digit code for pickup verification',
                      ),
                      value: _tokenRequired,
                      activeThumbColor: Colors.deepPurple,
                      onChanged: (v) =>
                          setState(() => _tokenRequired = v),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Max Per Customer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How many items one customer can reserve '
                      '(0 = unlimited)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _maxPerCustomerOptions.map((option) {
                        final selected = _maxPerCustomer == option;
                        final label =
                            option == 0 ? 'Unlimited' : '$option';
                        return ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          selectedColor: Colors.deepPurple.shade100,
                          onSelected: (_) =>
                              setState(() => _maxPerCustomer = option),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Save Settings',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}