// ═══════════════════════════════════════════════════════
// MIGO — Reservation Card Widget (PHASE H)
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/reservation_model.dart';
import 'countdown_timer_widget.dart';

class ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback? onTap;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.onTap,
  });

  Color _statusColor() {
    switch (reservation.status) {
      case 'reserved':
        return const Color(0xFF10B981); // green
      case 'picked_up':
        return const Color(0xFF3B82F6); // blue
      case 'expired':
        return const Color(0xFFEF4444); // red
      case 'cancelled':
        return const Color(0xFF6B7280); // grey
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _statusLabel() {
    switch (reservation.status) {
      case 'reserved':
        return 'ACTIVE';
      case 'picked_up':
        return 'PICKED UP';
      case 'expired':
        return 'EXPIRED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return reservation.status.toUpperCase();
    }
  }

  IconData _statusIcon() {
    switch (reservation.status) {
      case 'reserved':
        return Icons.timer_outlined;
      case 'picked_up':
        return Icons.check_circle_outline;
      case 'expired':
        return Icons.timer_off_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: Image + Info + Status ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: reservation.offerImageUrl.isNotEmpty
                      ? Image.network(
                          reservation.offerImageUrl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon(), size: 10, color: color),
                            const SizedBox(width: 4),
                            Text(
                              _statusLabel(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reservation.offerTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.store_outlined,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              reservation.businessName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Booking details ──
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _infoChip(
                    Icons.shopping_bag_outlined,
                    'x${reservation.quantity}',
                  ),
                  const SizedBox(width: 12),
                  _infoChip(
                    Icons.attach_money,
                    '${reservation.currency} ${reservation.totalAmount.toStringAsFixed(0)}',
                  ),
                  const Spacer(),
                  // Countdown timer
                  if (reservation.isActive)
                    CountdownTimerWidget(
                      expiresAt: reservation.expiresAt,
                      bookedAt: reservation.bookedAt,
                      compact: true,
                    ),
                ],
              ),
            ),

            // ── Pickup code (if active) ──
            if (reservation.isActive) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.qr_code_2,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pickup code: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    reservation.pickupCode,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],

            // ── Booked time ──
            const SizedBox(height: 8),
            Text(
              'Booked ${_formatDate(reservation.bookedAt)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image_outlined,
        color: Colors.grey.shade400,
        size: 28,
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade600),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return DateFormat('dd MMM, hh:mm a').format(date);
  }
}