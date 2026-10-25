import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/localization/locale_provider.dart';
import '../../models/reservation_model.dart';
import '../../services/reservation_service.dart';
import 'widgets/reservation_card.dart';
import 'reservation_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _uid = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Bookings')),
        body: const Center(child: Text('Please sign in')),
      );
    }

    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(isAr ? 'حجوزاتي' : 'My Bookings'),
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              bottom: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF7C3AED),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF7C3AED),
                tabs: [
                  Tab(text: isAr ? 'نشط' : 'Active'),
                  Tab(text: isAr ? 'مكتمل' : 'Completed'),
                  Tab(text: isAr ? 'منتهي' : 'Expired'),
                ],
              ),
            ),
            body: StreamBuilder<List<ReservationModel>>(
              stream: ReservationService.instance.streamMyReservations(_uid!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(isAr ? 'خطأ: ${snapshot.error}' : 'Error: ${snapshot.error}'),
                    ),
                  );
                }

                final all = snapshot.data ?? [];

                // Split into categories
                final active = all.where((r) => r.status == 'reserved').toList();
                final completed = all.where((r) => r.status == 'picked_up').toList();
                final expired = all
                    .where((r) => r.status == 'expired' || r.status == 'cancelled')
                    .toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(
                      active,
                      isAr ? 'لا توجد حجوزات نشطة' : 'No active bookings',
                      isAr ? 'احجز عرضًا لرؤيته هنا' : 'Book an offer to see it here',
                    ),
                    _buildList(
                      completed,
                      isAr ? 'لا توجد حجوزات مكتملة' : 'No completed bookings',
                      isAr ? 'ستظهر الحجوزات التي تم استلامها هنا' : 'Picked up bookings will appear here',
                    ),
                    _buildList(
                      expired,
                      isAr ? 'لا توجد حجوزات منتهية' : 'No expired bookings',
                      isAr ? 'تظهر الحجوزات المنتهية أو الملغاة هنا' : 'Expired or cancelled bookings appear here',
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(
    List<ReservationModel> bookings,
    String emptyTitle,
    String emptySubtitle,
  ) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                emptyTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return ReservationCard(
            reservation: booking,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReservationDetailScreen(
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