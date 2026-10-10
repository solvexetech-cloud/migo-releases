// ═══════════════════════════════════════════════════════
// MIGO — Reservation Detail Screen (PHASE H)
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/reservation_model.dart';
import '../../services/reservation_service.dart';
import 'widgets/countdown_timer_widget.dart';

class ReservationDetailScreen extends StatelessWidget {
  final String reservationId;

  const ReservationDetailScreen({
    super.key,
    required this.reservationId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation Details'),
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

          final reservation = ReservationModel.fromMap(
            snapshot.data!.id,
            snapshot.data!.data() as Map<String, dynamic>,
          );

          return _buildBody(context, reservation);
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

                // ── QR Code (if active) ──
                if (res.isActive) _buildQRCard(res),

                if (res.isActive) const SizedBox(height: 16),

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

                // ── Booking info ──
                _buildInfoCard(res, theme),

                const SizedBox(height: 16),

                // ── Shop info ──
                _buildShopCard(context, res, theme),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // ── Action buttons ──
        if (res.isActive) _buildActionButtons(context, res),
      ],
    );
  }

  Widget _buildStatusBanner(ReservationModel res) {
    final (color, label, icon) = switch (res.status) {
      'reserved' => (const Color(0xFF10B981), 'ACTIVE RESERVATION', Icons.check_circle),
      'picked_up' => (const Color(0xFF3B82F6), 'PICKED UP', Icons.done_all),
      'expired' => (const Color(0xFFEF4444), 'EXPIRED', Icons.timer_off),
      'cancelled' => (const Color(0xFF6B7280), 'CANCELLED', Icons.cancel),
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

  Widget _buildQRCard(ReservationModel res) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Text(
            'SHOW THIS AT THE SHOP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // QR Code
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.qr_code_2,
                size: 180,
                color: Colors.grey.shade800,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 6-digit code
          const Text(
            'Or use pickup code',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            res.pickupCode.split('').join(' '),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ReservationModel res, ThemeData theme) {
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
            'BOOKING INFO',
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
          _infoRow('Booked', _formatDate(res.bookedAt)),
          if (res.isActive)
            _infoRow('Expires', _formatDate(res.expiresAt)),
        ],
      ),
    );
  }

  Widget _buildShopCard(
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
            'SHOP',
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
              Icon(Icons.store, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  res.businessName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (res.businessPhone.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _launchPhone(res.businessPhone),
              child: Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text(
                    res.businessPhone,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildActionButtons(BuildContext context, ReservationModel res) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (res.businessPhone.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _launchPhone(res.businessPhone),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call Shop'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmCancel(context, res),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Booking'),
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

  Future<void> _confirmCancel(
      BuildContext context, ReservationModel res) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text(
          'Are you sure you want to cancel this reservation? The slot will be released.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ReservationService.instance.cancelReservation(res.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Reservation cancelled'),
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