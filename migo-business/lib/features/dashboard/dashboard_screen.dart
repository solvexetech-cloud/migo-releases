import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/migo_theme.dart';
import '../../services/auth_service.dart';
import '../bookings/shop_bookings_screen.dart';
import '../offers/my_offers_screen.dart';
import '../scan/scan_qr_screen.dart';
import '../offers/my_flyers_screen.dart'; // പുതിയത്
import '../analytics/business_analytics_screen.dart';
import '../profile/profile_screen.dart';
import '../bookings/claims_history_screen.dart'; // പുതിയത്



/// PHASE I — Business Dashboard
/// Responsive: sidebar on PC, drawer on mobile
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: isWide
          ? null
          : AppBar(
              title: const Text('MIGO Business'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _handleSignOut,
                ),
              ],
            ),
      drawer: isWide ? null : _buildDrawer(),
      body: isWide
          ? Row(
              children: [
                _buildSidebar(),
                Expanded(child: _buildContent()),
              ],
            )
          : _buildContent(),
    );
  }

  // ═══════════════════════════════════════════════════
  // SIDEBAR (PC)
  // ═══════════════════════════════════════════════════
  Widget _buildSidebar() {
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
          // Logo
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
                  child: const Text('🎁', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MIGO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    Text(
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

          // Nav
          _sidebarItem(0, Icons.dashboard_outlined, 'Dashboard'),
          _sidebarItem(1, Icons.local_offer_outlined, 'My Offers'),
          _sidebarItem(7, Icons.menu_book_outlined, 'My Flyers'),
          _sidebarItem(2, Icons.event_note_outlined, 'Bookings'),
          _sidebarItem(6, Icons.people_outline, 'Customer Claims'), // പുതിയത്
          _sidebarItem(3, Icons.qr_code_scanner, 'Scan QR'),
          _sidebarItem(4, Icons.analytics_outlined, 'Analytics'),
          _sidebarItem(5, Icons.settings_outlined, 'Settings'),

          const Spacer(),

          // Sign out
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: _handleSignOut,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign out'),
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
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? MigoColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? MigoColors.primary : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 12),
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
    );
  }

  // ═══════════════════════════════════════════════════
  // DRAWER (Mobile)
  // ═══════════════════════════════════════════════════
  Widget _buildDrawer() {
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
                  Text('🎁', style: TextStyle(fontSize: 32)),
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
            _drawerItem(6, Icons.people_outline, 'Customer Claims'), // പുതിയത്
            _drawerItem(3, Icons.qr_code_scanner, 'Scan QR'),
            _drawerItem(4, Icons.analytics_outlined, 'Analytics'),
            _drawerItem(5, Icons.settings_outlined, 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(int index, IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  // ═══════════════════════════════════════════════════
  // CONTENT
  // ═══════════════════════════════════════════════════
  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const MyOffersScreen();
      case 2:
        return _buildBookingsTab();
      case 3:
        return _buildScanTab();
      case 4:
        return _buildAnalyticsTab();
      case 5:
        return _buildProfileTab();
      case 6: 
        return _buildClaimsTab();
      case 7:
        return const MyFlyersScreen();
      default:
        return Center(
          child: Text(
            _contentTitles[_selectedIndex],
            style: const TextStyle(
              fontSize: 18,
              color: MigoColors.textSecondary,
            ),
          ),
        );
    }
  }

  // ─────────────────────────────────────────────────────
  // Bookings tab
  // ─────────────────────────────────────────────────────
  Widget _buildBookingsTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not signed in'));
    }

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
        if (docs.isEmpty) {
          return const Center(child: Text('No business linked'));
        }
        return ShopBookingsScreen(businessId: docs.first.id);
      },
    );
  }

  // ─────────────────────────────────────────────────────
  // Scan QR tab
  // ─────────────────────────────────────────────────────
  Widget _buildScanTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not signed in'));
    }

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
        if (docs.isEmpty) {
          return const Center(child: Text('No business linked'));
        }
        return ScanQrScreen(businessId: docs.first.id);
      },
    );
  }

  // ─────────────────────────────────────────────────────
  // Claims tab
  // ─────────────────────────────────────────────────────
  Widget _buildClaimsTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not signed in'));
    }

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
        if (docs.isEmpty) {
          return const Center(child: Text('No business linked'));
        }
        return ClaimsHistoryScreen(businessId: docs.first.id);
      },
    );
  }


  Widget _buildAnalyticsTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not signed in'));
    }

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
        if (docs.isEmpty) {
          return const Center(child: Text('No business linked'));
        }
        return BusinessAnalyticsScreen(businessId: docs.first.id);
      },
    );
  }

  Widget _buildProfileTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not signed in'));
    }

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
        if (docs.isEmpty) {
          return const Center(child: Text('No business linked'));
        }
        return ProfileScreen(businessId: docs.first.id);
      },
    );
  }

  static const _contentTitles = [
    'Dashboard',
    'My Offers',
    'Bookings',
    'Scan QR',
    'Analytics',
    'Settings',
    'Customer Claims',
    'My Flyers',
  ];

  // ═══════════════════════════════════════════════════
  // HOME TAB
  // ═══════════════════════════════════════════════════
    Widget _buildHomeTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not signed in'));
    }

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
        if (docs.isEmpty) {
          return const Center(child: Text('No business linked'));
        }

        final business = docs.first.data() as Map<String, dynamic>;
        final businessId = docs.first.id;

        // Fetch offers and claims
        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            FirebaseFirestore.instance
                .collection('offers')
                .where('businessId', isEqualTo: businessId)
                .get(),
            FirebaseFirestore.instance
                .collection('claims')
                .where('businessId', isEqualTo: businessId)
                .where('status', isEqualTo: 'redeemed')
                .get(),
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
                  Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    business['name'] ?? 'Your Business',
                    style: const TextStyle(
                      color: MigoColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats
                                    _statCard(
                    icon: Icons.local_offer_outlined,
                    label: 'Total Offers',
                    value: totalOffers.toString(),
                    color: MigoColors.info,
                  ),
                  const SizedBox(height: 10),
                  _statCard(
                    icon: Icons.check_circle_outline,
                    label: 'Redeemed Claims',
                    value: redeemedCount.toString(),
                    color: MigoColors.success,
                  ),
                  const SizedBox(height: 10),
                  _statCard(
                    icon: Icons.monetization_on_outlined,
                    label: 'Total Revenue (QAR)',
                    value: totalRevenue.toStringAsFixed(0),
                    color: MigoColors.warning,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════
  // STAT CARD — Horizontal (no overflow)
  // ═══════════════════════════════════════════════════
  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MigoColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // SIGN OUT
  // ═══════════════════════════════════════════════════
  Future<void> _handleSignOut() async {
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