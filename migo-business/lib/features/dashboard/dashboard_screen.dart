// migo-business/lib/features/dashboard/dashboard_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_theme.dart';
import '../../services/auth_service.dart';
import '../bookings/shop_bookings_screen.dart';
import '../offers/my_offers_screen.dart';
import '../scan/scan_qr_screen.dart';
import '../offers/my_flyers_screen.dart';
import '../analytics/business_analytics_screen.dart';
import '../profile/profile_screen.dart';
import '../claims/business_claims_screen.dart';
import '../demands/business_demands_feed_screen.dart';
import '../scan/shop_counters_screen.dart';
import '../creator/shop_creators_screen.dart';
import '../creator/shop_creator_content_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _showRevenue = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';
        final isWide = MediaQuery.of(context).size.width >= 900;

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: isWide
                ? null
                : AppBar(
                    title: const Text('MIGO Business'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () => _handleSignOut(isAr),
                      ),
                    ],
                  ),
            drawer: isWide ? null : _buildDrawer(isAr),
            body: isWide
                ? Row(
                    children: [
                      _buildSidebar(isAr),
                      Expanded(child: _buildContent(isAr)),
                    ],
                  )
                : _buildContent(isAr),
          ),
        );
      },
    );
  }

  // SIDEBAR
  Widget _buildSidebar(bool isAr) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [MigoColors.primary, MigoColors.primaryDark],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [MigoColors.accent, MigoColors.accentDark],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.storefront, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MIGO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const Text(
                      'BUSINESS',
                      style: TextStyle(
                        color: MigoColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _sidebarItem(0, Icons.dashboard_outlined, 'Dashboard'),
                  _sidebarItem(1, Icons.local_offer_outlined, 'My Offers'),
                  _sidebarItem(7, Icons.menu_book_outlined, 'My Flyers'),
                  _sidebarItem(2, Icons.event_note_outlined, 'Bookings'),
                  _sidebarItem(6, Icons.people_outline, 'Customer Claims'),
                  _sidebarItem(8, Icons.gavel, 'Community Demands'),
                  _sidebarItem(3, Icons.qr_code_scanner, 'Scan QR'),
                  _sidebarItem(9, Icons.qr_code_2, 'Shop Counters'),
                  _sidebarItem(10, Icons.people_outline, 'Creators'),
                  _sidebarItem(4, Icons.analytics_outlined, 'Analytics'),
                  _sidebarItem(5, Icons.settings_outlined, 'Settings'),
                ],
              ),
            ),
          ),
                    Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _handleSignOut(isAr),
              icon: const Icon(Icons.logout, size: 18),
              label: Text(isAr ? 'تسجيل الخروج' : 'Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    final selected = _selectedIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [MigoColors.accent, MigoColors.accentDark],
              )
            : null,
        color: selected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: MigoColors.accent.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? MigoColors.primary : Colors.white70,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? MigoColors.primary : Colors.white,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(bool isAr) {
    return Drawer(
      child: Container(
        color: MigoColors.primary,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: MigoColors.primaryDark),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.storefront, color: Colors.white, size: 32),
                  SizedBox(height: 6),
                  Text(
                    'MIGO Business',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            _drawerItem(0, Icons.dashboard_outlined, 'Dashboard'),
            _drawerItem(1, Icons.local_offer_outlined, 'My Offers'),
            _drawerItem(7, Icons.menu_book_outlined, 'My Flyers'),
            _drawerItem(2, Icons.event_note_outlined, 'Bookings'),
            _drawerItem(6, Icons.people_outline, 'Customer Claims'),
            _drawerItem(8, Icons.gavel, 'Community Demands'),
            _drawerItem(3, Icons.qr_code_scanner, 'Scan QR'),
            _drawerItem(9, Icons.qr_code_2, 'Shop Counters'),
            _drawerItem(10, Icons.people_outline, 'Creators'),
            _drawerItem(4, Icons.analytics_outlined, 'Analytics'),
            _drawerItem(5, Icons.settings_outlined, 'Settings'),
            const Divider(color: Colors.white24),
                            ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white70),
                  title: Text(isAr ? 'تسجيل الخروج' : 'Sign out', style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _handleSignOut(isAr);
                  },
                ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(int index, IconData icon, String label) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        onTap: () {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildContent(bool isAr) {
    switch (_selectedIndex) {
      case 0: return _buildHomeTab(isAr);
      case 1: return const MyOffersScreen();
      case 2: return _buildBookingsTab();
      case 3: return _buildScanTab();
      case 4: return _buildAnalyticsTab();
      case 5: return _buildProfileTab();
      case 6: return _buildBusinessDependentTab((id) => BusinessClaimsScreen(businessId: id));
      case 7: return const MyFlyersScreen();
      case 8: return const BusinessDemandsFeedScreen();
      case 9: return _buildBusinessDependentTab((id) => ShopCountersScreen(businessId: id));
      case 10: return _buildBusinessDependentTab((id) => ShopCreatorsScreen(businessId: id));
      case 11: return _buildBusinessDependentTab((id) => ShopCreatorContentScreen(businessId: id));
      default: return const SizedBox();
    }
  }

  Widget _buildBookingsTab() => _buildBusinessDependentTab((id) => ShopBookingsScreen(businessId: id));
  Widget _buildScanTab() => _buildBusinessDependentTab((id) => ScanQrScreen(businessId: id));
  Widget _buildAnalyticsTab() => _buildBusinessDependentTab((id) => BusinessAnalyticsScreen(businessId: id));
  Widget _buildProfileTab() => _buildBusinessDependentTab((id) => ProfileScreen(businessId: id));

  Widget _buildBusinessDependentTab(Widget Function(String) builder) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not signed in'));

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('businesses')
          .where('ownerUid', isEqualTo: uid)
          .limit(1)
          .get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No business linked'));
        return builder(docs.first.id);
      },
    );
  }

  Widget _buildHomeTab(bool isAr) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not signed in'));

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('businesses')
          .where('ownerUid', isEqualTo: uid)
          .limit(1)
          .get(),
      builder: (context, bizSnap) {
        if (bizSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = bizSnap.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No business linked'));

        final business = docs.first.data() as Map<String, dynamic>;
        final businessId = docs.first.id;

        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            FirebaseFirestore.instance.collection('offers').where('businessId', isEqualTo: businessId).get(),
            FirebaseFirestore.instance.collection('claims').where('businessId', isEqualTo: businessId).where('status', isEqualTo: 'redeemed').get(),
          ]),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final offersSnap = snap.data![0] as QuerySnapshot;
            final redeemedSnap = snap.data![1] as QuerySnapshot;

            final totalOffers = offersSnap.docs.length;
            final redeemedCount = redeemedSnap.docs.length;
            
            double totalRevenue = 0;
            for (var doc in redeemedSnap.docs) {
              final data = doc.data() as Map<String, dynamic>;
              totalRevenue += (data['offerPrice'] as num?)?.toDouble() ?? 0;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [MigoColors.primary, MigoColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          business['name'] ?? 'Your Business',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('demand_groups')
                        .where('status', whereIn: ['threshold_reached', 'bidding'])
                        .get(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: InkWell(
                          onTap: () => setState(() => _selectedIndex = 8),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: MigoColors.primary, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: MigoColors.primary.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: MigoColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.notifications_active, color: MigoColors.primary, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$count New Demand${count > 1 ? 's' : ''}!',
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: MigoColors.primaryDark),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Waiting for your bids',
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: MigoColors.primary),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  InkWell(
                    onTap: () => setState(() => _selectedIndex = 3),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: MigoColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: MigoColors.accent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: MigoColors.accent.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: MigoColors.accent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.qr_code_scanner, color: MigoColors.accentDark, size: 36),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scan & Redeem',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Scan customer QR to redeem offer',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: MigoColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: MigoColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text(
                    'Statistics',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          icon: Icons.local_offer_outlined,
                          label: 'Total Offers',
                          value: totalOffers.toString(),
                          color: MigoColors.info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          icon: Icons.check_circle_outline,
                          label: 'Redeemed Claims',
                          value: redeemedCount.toString(),
                          color: MigoColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _revenueCard(
                          isAr: isAr,
                          totalRevenue: totalRevenue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _revenueCard({
    required bool isAr,
    required double totalRevenue,
  }) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MigoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MigoColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MigoColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.monetization_on_outlined, color: MigoColors.warning, size: 20),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _showRevenue ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                  color: MigoColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _showRevenue = !_showRevenue;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _showRevenue
                  ? '${totalRevenue.toStringAsFixed(0)} QAR'
                  : '***** QAR',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: MigoColors.warning,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Total Revenue',
            style: TextStyle(
              fontSize: 11,
              color: MigoColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MigoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MigoColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: MigoColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(bool isAr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.instance.signOut();
    }
  }
}