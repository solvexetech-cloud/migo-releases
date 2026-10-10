// ═══════════════════════════════════════════════════════
// MIGO — Reservation Detail (Shop View) — PHASE H
// Business owner sees customer + pickup actions
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/reservation_model.dart';
import '../../services/reservation_service.dart';
import '../reserve/widgets/countdown_timer_widget.dart';

class ReservationDetailShopScreen extends StatelessWidget {
  final String reservationId;

  const ReservationDetailShopScreen({
    super.key,
    required this.reservationId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .doc(reservationId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Reservation not found'));
          }

          final res = ReservationModel.fromMap(
            snapshot.data!.id,
            snapshot.data!.data() as Map<String, dynamic>,
          );

          return _buildBody(context, res);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReservationModel res) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status banner ──
                _buildStatusBanner(res),
                const SizedBox(height: 16),

                // ── Countdown (if active) ──
                if (res.isActive)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CountdownTimerWidget(
                      expiresAt: res.expiresAt,
                      bookedAt: res.bookedAt,
                    ),
                  ),
                if (res.isActive) const SizedBox(height: 16),

                // ── Customer info ──
                _buildCustomerCard(context, res, theme),
                const SizedBox(height: 16),

                // ── Booking info ──
                _buildBookingCard(res, theme),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        if (res.isActive) _buildActions(context, res),
      ],
    );
  }

  Widget _buildStatusBanner(ReservationModel res) {
    final (color, label, icon) = switch (res.status) {
      'reserved' =>
        (const Color(0xFF10B981), 'ACTIVE BOOKING', Icons.check_circle),
      'picked_up' =>
        (const Color(0xFF3B82F6), 'PICKED UP', Icons.done_all),
      'expired' =>
        (const Color(0xFFEF4444), 'EXPIRED', Icons.timer_off),
      'cancelled' =>
        (const Color(0xFF6B7280), 'CANCELLED', Icons.cancel),
      _ => (const Color(0xFF6B7280), res.status.toUpperCase(), Icons.info),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(
      BuildContext context, ReservationModel res, ThemeData theme) {
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
            'CUSTOMER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor:
                    const Color(0xFF7C3AED).withValues(alpha: 0.1),
                child: Text(
                  (res.userName.isNotEmpty ? res.userName[0] : '?')
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.userName.isNotEmpty ? res.userName : 'Customer',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (res.userPhone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            res.userPhone,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(ReservationModel res, ThemeData theme) {
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
            'BOOKING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('Offer', res.offerTitle),
          _infoRow('Quantity', 'x${res.quantity}'),
          _infoRow(
            'Total',
            '${res.currency} ${res.totalAmount.toStringAsFixed(0)}',
            valueColor: const Color(0xFF7C3AED),
          ),
          _infoRow('Pickup Code', '#${res.pickupCode}'),
          _infoRow('Booked', _formatDate(res.bookedAt)),
          if (res.isActive)
            _infoRow('Expires', _formatDate(res.expiresAt)),
          if (res.pickedUpAt != null)
            _infoRow('Picked Up', _formatDate(res.pickedUpAt!)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, ReservationModel res) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (res.userPhone.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _launchPhone(res.userPhone),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call Customer'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: Colors.green.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmPickup(context, res),
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark as Picked Up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmNoShow(context, res),
                icon: const Icon(Icons.timer_off),
                label: const Text('Mark as No-Show'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPickup(
      BuildContext context, ReservationModel res) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Pickup?'),
        content: Text(
          'Mark ${res.userName}\'s booking as picked up?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ReservationService.instance.markPickedUp(res.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Marked as picked up'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _confirmNoShow(
      BuildContext context, ReservationModel res) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as No-Show?'),
        content: const Text(
          'Customer didn\'t pick up. This will release the slot and log a no-show.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Mark No-Show'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ReservationService.instance
          .markNoShow(res.id, reason: 'manual');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Marked as no-show'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}