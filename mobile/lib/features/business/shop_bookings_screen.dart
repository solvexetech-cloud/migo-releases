// ═══════════════════════════════════════════════════════
// MIGO — Shop Bookings Screen (PHASE H)
// Business owner's bookings dashboard
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../models/reservation_model.dart';
import '../../services/reservation_service.dart';
import '../reserve/widgets/countdown_timer_widget.dart';
import 'reservation_detail_shop_screen.dart';

class ShopBookingsScreen extends StatefulWidget {
  final String businessId;

  const ShopBookingsScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<ShopBookingsScreen> createState() => _ShopBookingsScreenState();
}

class _ShopBookingsScreenState extends State<ShopBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Bookings'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF7C3AED),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Expired'),
          ],
        ),
      ),
      body: StreamBuilder<List<ReservationModel>>(
        stream: ReservationService.instance
            .streamBusinessReservations(widget.businessId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }

          final all = snapshot.data ?? [];

          final active = all.where((r) => r.status == 'reserved').toList();
          final completed = all.where((r) => r.status == 'picked_up').toList();
          final expired = all
              .where((r) =>
                  r.status == 'expired' || r.status == 'cancelled')
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(active, 'No active bookings', true),
              _buildList(completed, 'No completed bookings', false),
              _buildList(expired, 'No expired bookings', false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(
    List<ReservationModel> bookings,
    String emptyText,
    bool showActions,
  ) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              emptyText,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _ShopBookingCard(
            reservation: booking,
            showActions: showActions,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReservationDetailShopScreen(
                    reservationId: booking.id,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Shop Booking Card
// ─────────────────────────────────────────────────────
class _ShopBookingCard extends StatelessWidget {
  final ReservationModel reservation;
  final bool showActions;
  final VoidCallback onTap;

  const _ShopBookingCard({
    required this.reservation,
    required this.showActions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top: Customer + Timer ──
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  child: Text(
                    (reservation.userName.isNotEmpty
                            ? reservation.userName[0]
                            : '?')
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.userName.isNotEmpty
                            ? reservation.userName
                            : 'Customer',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (reservation.userPhone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          reservation.userPhone,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (reservation.isActive)
                  CountdownTimerWidget(
                    expiresAt: reservation.expiresAt,
                    bookedAt: reservation.bookedAt,
                    compact: true,
                  ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Middle: Offer info ──
            Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reservation.offerTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                _chip(
                  Icons.inventory_2_outlined,
                  'x${reservation.quantity}',
                ),
                const SizedBox(width: 10),
                _chip(
                  Icons.attach_money,
                  '${reservation.currency} ${reservation.totalAmount.toStringAsFixed(0)}',
                ),
                const Spacer(),
                if (reservation.pickupCode.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${reservation.pickupCode}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),

            // ── Actions ──
            if (showActions && reservation.isActive) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (reservation.userPhone.isNotEmpty)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Call customer
                        },
                        icon: const Icon(Icons.phone, size: 16),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: Colors.green.shade700,
                        ),
                      ),
                    ),
                  if (reservation.userPhone.isNotEmpty)
                    const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onTap(),
                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                      label: const Text('Scan QR'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade600),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}