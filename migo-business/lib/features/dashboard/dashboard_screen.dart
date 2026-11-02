import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/localization/locale_provider.dart'; // 🆕 അറബിക് ഭാഷയ്ക്ക് വേണ്ടി
import '../../core/theme/migo_gradients.dart'; // 🆕 ഗ്രേഡിയന്റിന് വേണ്ടി
import '../../core/theme/migo_theme.dart';
import '../../services/auth_service.dart';
import '../bookings/shop_bookings_screen.dart';
import '../offers/my_offers_screen.dart';
import '../scan/scan_qr_screen.dart';
import '../offers/my_flyers_screen.dart';
import '../analytics/business_analytics_screen.dart';
import '../profile/profile_screen.dart';
import '../bookings/claims_history_screen.dart';
import '../demands/demand_bids_screen.dart';

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
                    title: Text(isAr ? 'ميجو بيزنس' : 'MIGO Business'),
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

  // ═══════════════════════════════════════════════════
  // SIDEBAR (PC)
  // ═══════════════════════════════════════════════════
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'ميجو' : 'MIGO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    Text(
                      isAr ? 'بيزنس' : 'BUSINESS',
                      style: const TextStyle(
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

          // Nav Items
          _sidebarItem(0, Icons.dashboard_outlined, isAr ? 'لوحة التحكم' : 'Dashboard'),
          _sidebarItem(1, Icons.local_offer_outlined, isAr ? 'عروضي' : 'My Offers'),
          _sidebarItem(7, Icons.menu_book_outlined, isAr ? 'منشوراتي' : 'My Flyers'),
          _sidebarItem(2, Icons.event_note_outlined, isAr ? 'الحجوزات' : 'Bookings'),
          _sidebarItem(6, Icons.people_outline, isAr ? 'مطالبات العملاء' : 'Customer Claims'),
          _sidebarItem(8, Icons.gavel, isAr ? 'طلبات المجتمع' : 'Community Demands'),
          _sidebarItem(3, Icons.qr_code_scanner, isAr ? 'مسح QR' : 'Scan QR'),
          _sidebarItem(4, Icons.analytics_outlined, isAr ? 'التحليلات' : 'Analytics'),
          _sidebarItem(5, Icons.settings_outlined, isAr ? 'الإعدادات' : 'Settings'),

          const Spacer(),

          // Sign out
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
  Widget _buildDrawer(bool isAr) {
    return Drawer(
      child: Container(
        color: MigoColors.primary,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: MigoColors.primaryDark),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'ميجو بيزنس' : 'MIGO Business',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            _drawerItem(0, Icons.dashboard_outlined, isAr ? 'لوحة التحكم' : 'Dashboard'),
            _drawerItem(1, Icons.local_offer_outlined, isAr ? 'عروضي' : 'My Offers'),
            _drawerItem(7, Icons.menu_book_outlined, isAr ? 'منشوراتي' : 'My Flyers'),
            _drawerItem(2, Icons.event_note_outlined, isAr ? 'الحجوزات' : 'Bookings'),
            _drawerItem(6, Icons.people_outline, isAr ? 'مطالبات العملاء' : 'Customer Claims'),
            _drawerItem(8, Icons.gavel, isAr ? 'طلبات المجتمع' : 'Community Demands'),
            _drawerItem(3, Icons.qr_code_scanner, isAr ? 'مسح QR' : 'Scan QR'),
            _drawerItem(4, Icons.analytics_outlined, isAr ? 'التحليلات' : 'Analytics'),
            _drawerItem(5, Icons.settings_outlined, isAr ? 'الإعدادات' : 'Settings'),
          ],
        ),
      ),
    );
  }

    Widget _drawerItem(int index, IconData icon, String label) {
    return Material(
      color: Colors.transparent, // 👈 ഈ വരി നിർബന്ധമായും ചേർക്കുക
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

  // ═══════════════════════════════════════════════════
  // CONTENT ROUTER
  // ═══════════════════════════════════════════════════
  Widget _buildContent(bool isAr) {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab(isAr);
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
      case 8:
        return const DemandBidsScreen();
      case 7:
        return const MyFlyersScreen();
      default:
        return const SizedBox();
    }
  }

  // ─────────────────────────────────────────────────────
  // TABS (Bookings, Scan, Claims, Analytics, Profile)
  // ─────────────────────────────────────────────────────
  Widget _buildBookingsTab() => _buildBusinessDependentTab((id) => ShopBookingsScreen(businessId: id));
  Widget _buildScanTab() => _buildBusinessDependentTab((id) => ScanQrScreen(businessId: id));
  Widget _buildClaimsTab() => _buildBusinessDependentTab((id) => ClaimsHistoryScreen(businessId: id));
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

  // ═══════════════════════════════════════════════════
  // HOME TAB (REDESIGNED)
  // ═══════════════════════════════════════════════════
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
                  // 🆕 മനോഹരമായ ഗ്രേഡിയന്റ് ഹെഡർ
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
                        Text(
                          isAr ? 'مرحباً بعودتك!' : 'Welcome back!',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          business['name'] ?? (isAr ? 'نشاطك التجاري' : 'Your Business'),
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

                  // 🆕 വലിയ Scan QR ബട്ടൺ
                  InkWell(
                    onTap: () => setState(() => _selectedIndex = 3), // Navigate to Scan Tab
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? 'مسح واسترداد' : 'Scan & Redeem',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isAr ? 'امسح رمز QR الخاص بالعميل للاسترداد' : 'Scan customer QR to redeem offer',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: MigoColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(isAr ? Icons.arrow_back_ios : Icons.arrow_forward_ios, size: 16, color: MigoColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Text(
                    isAr ? 'الإحصائيات' : 'Statistics',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // 🆕 സ്റ്റാറ്റസ് കാർഡുകൾ (Grid Layout)
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          icon: Icons.local_offer_outlined,
                          label: isAr ? 'إجمالي العروض' : 'Total Offers',
                          value: totalOffers.toString(),
                          color: MigoColors.info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          icon: Icons.check_circle_outline,
                          label: isAr ? 'المطالبات المستردة' : 'Redeemed Claims',
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
                        child: _statCard(
                          icon: Icons.monetization_on_outlined,
                          label: isAr ? 'إجمالي الإيرادات' : 'Total Revenue',
                          value: '${totalRevenue.toStringAsFixed(0)} QAR',
                          color: MigoColors.warning,
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

  // ═══════════════════════════════════════════════════
  // STAT CARD — NEW DESIGN
  // ═══════════════════════════════════════════════════
  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      height: 140, // 👈 ഈ വരി പുതിയതായി ചേർക്കുക
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

  // ═══════════════════════════════════════════════════
  // SIGN OUT
  // ═══════════════════════════════════════════════════
  Future<void> _handleSignOut(bool isAr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAr ? 'تسجيل الخروج؟' : 'Sign out?'),
        content: Text(isAr ? 'هل أنت متأكد أنك تريد تسجيل الخروج؟' : 'Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isAr ? 'تسجيل الخروج' : 'Sign out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.instance.signOut();
    }
  }
}