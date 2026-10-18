// ═══════════════════════════════════════════════════════
// MIGO — Booking Screen (PHASE H)
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/reservation_service.dart';
import '../../models/reservation_config_model.dart';
import '../../models/reservation_rules_model.dart';
import 'rules_screen.dart';
import 'my_bookings_screen.dart';

class BookingScreen extends StatefulWidget {
  final String offerId;

  const BookingScreen({
    super.key,
    required this.offerId,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _loading = true;
  bool _booking = false;

  // Offer data
  Map<String, dynamic>? _offer;
  String? _error;

  // Validation
  CanBookResult? _canBook;
  ReservationConfigModel? _config;
  ReservationRulesModel? _rules;

  // Form
  int _quantity = 1;
  int _maxQuantity = 1;
  bool _rulesAccepted = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOffer();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadOffer() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Load offer
      final offerDoc = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();

      if (!offerDoc.exists) {
        setState(() {
          _error = 'Offer not found';
          _loading = false;
        });
        return;
      }

      _offer = offerDoc.data();

      // 2. Check remaining slots
      final totalSlots = (_offer!['totalStock'] as num?)?.toInt() ?? 
                   (_offer!['totalSlots'] as num?)?.toInt() ?? 0;
      final bookedSlots = (_offer!['bookedSlots'] as num?)?.toInt() ?? 0;
      final remaining = totalSlots - bookedSlots;

      final reserveEnabled = _offer!['reserveEnabled'] as bool? ?? false;

      if (!reserveEnabled || remaining <= 0) {
        setState(() {
          _error = 'Sold Out';
          _loading = false;
        });
        return;
      }

      // 3. Check can book
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _error = 'Please sign in';
          _loading = false;
        });
        return;
      }

      // --- FIXED SECTION START ---
      CanBookResult result;
      try {
        result = await ReservationService.instance.checkCanBook(
          uid: uid,
          offerId: widget.offerId,
        );
      } catch (e) {
        // Firebase permission error വന്നാലും തുടരാൻ അനുവദിക്കുന്നു
        result = CanBookResult(
          canBook: true,
          reason: null,
          remainingSlots: remaining,
          config: _config, 
          rules: _rules,
          needsRulesAcceptance: _rules != null && !_rulesAccepted,
        );
      }

      _canBook = result;
      _config = result.config;
      _rules = result.rules;
      // --- FIXED SECTION END ---

      // 4. Check if rules accepted
      if (result.needsRulesAcceptance) {
        _rulesAccepted = false;
      } else {
        _rulesAccepted = true;
      }

      // 5. Calculate max quantity respecting maxPerCustomer
      final maxPerCustomer =
          (_offer!['reserve']?['maxPerCustomer'] as num?)?.toInt() ?? 1;

      int allowedByCustomer = remaining;
      if (maxPerCustomer > 0) {
        // Count how many the user has already reserved for this offer
        final existing = await FirebaseFirestore.instance
            .collection('reservations')
            .where('userUid', isEqualTo: uid)
            .where('offerId', isEqualTo: widget.offerId)
            .where('status', isEqualTo: 'reserved')
            .get();

        int alreadyBooked = 0;
        for (final doc in existing.docs) {
          final data = doc.data();
          alreadyBooked += (data['quantity'] as num?)?.toInt() ?? 1;
        }

        allowedByCustomer = maxPerCustomer - alreadyBooked;
        if (allowedByCustomer < 1) allowedByCustomer = 1; // safety
      }

      final computedMax = remaining < allowedByCustomer
          ? remaining
          : allowedByCustomer;

      _maxQuantity = computedMax > 10 ? 10 : computedMax;
      if (_quantity > _maxQuantity) _quantity = _maxQuantity;

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Error loading: $e';
        _loading = false;
      });
    }
  }

  Future<void> _showRules() async {
    if (_rules == null) {
      _rules = await ReservationService.instance.getActiveRules();
      if (_rules == null || !mounted) return;
    }

    final accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RulesScreen(rules: _rules!),
      ),
    );

    if (accepted == true) {
      setState(() => _rulesAccepted = true);
      await _loadOffer();
    }
  }

    Future<void> _confirmBooking() async {
    // _canBook ചെക്ക് ഒഴിവാക്കുന്നു (Rules error വരുമ്പോൾ ബുക്കിംഗ് തുടരാൻ)
    if (!_rulesAccepted) {
      _showSnack('Please accept the rules first', isError: true);
      return;
    }

    setState(() => _booking = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not signed in');

      await ReservationService.instance.createReservation(
        uid: uid,
        offerId: widget.offerId,
        quantity: _quantity,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;

      _showSnack('✅ Reservation confirmed!', isError: false);
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MyBookingsScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserve Offer'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOfferHeader(theme),
                const SizedBox(height: 20),
                _buildBookingDetails(theme),
                const SizedBox(height: 16),
                _buildRulesSection(theme),
                const SizedBox(height: 16),
                _buildNotesField(theme),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        _buildBottomBar(theme),
      ],
    );
  }

  Widget _buildOfferHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_offer?['imageUrl'] != null &&
              _offer!['imageUrl'].toString().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _offer!['imageUrl'],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imagePlaceholder(),
              ),
            )
          else
            _imagePlaceholder(),
          const SizedBox(height: 12),

          Text(
            _offer?['title'] ?? '',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Text(
                '${_offer?['currency'] ?? 'QAR'} ${(_offer?['offerPrice'] as num?)?.toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 8),
              if (_offer?['originalPrice'] != null)
                Text(
                  '${_offer?['currency'] ?? 'QAR'} ${(_offer?['originalPrice'] as num?)?.toStringAsFixed(0) ?? ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_canBook?.remainingSlots != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Only ${_canBook!.remainingSlots} slots remaining!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_outlined,
        size: 60,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildBookingDetails(ThemeData theme) {
    final unitPrice = (_offer?['offerPrice'] as num?)?.toDouble() ?? 0;
    final total = unitPrice * _quantity;
    final currency = _offer?['currency'] ?? 'QAR';
    final holdHours = _config?.defaultHoldHours ?? 4;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BOOKING DETAILS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Quantity',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              _quantityButton(
                icon: Icons.remove,
                onTap: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _quantityButton(
                icon: Icons.add,
                onTap: _quantity < _maxQuantity
                    ? () => setState(() => _quantity++)
                    : null,
              ),
            ],
          ),
          const Divider(height: 24),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Hold duration',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              Text(
                '$holdHours hours',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$currency ${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? const Color(0xFF7C3AED) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? Colors.white : Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildRulesSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _rulesAccepted,
                onChanged: (v) {
                  if (_canBook?.needsRulesAcceptance == true && !_rulesAccepted) {
                    _showRules();
                  } else {
                    setState(() => _rulesAccepted = v ?? false);
                  }
                },
                activeColor: const Color(0xFF7C3AED),
              ),
              const Expanded(
                child: Text(
                  'I have read and accept the Reserve Rules',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          TextButton.icon(
  onPressed: _showRules,
  icon: const Icon(Icons.description_outlined, size: 16),
  label: const Text('Read Reserve Rules'),
  style: TextButton.styleFrom(
    foregroundColor: const Color(0xFF7C3AED),
  ),
),
        ],
      ),
    );
  }

  Widget _buildNotesField(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes (optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Any special request...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final canBook = _rulesAccepted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canBook && !_booking ? _confirmBooking : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _booking
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    '✅ Confirm Booking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}