import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import '../../core/theme/migo_gradients.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../business/my_business_screen.dart';
import '../deals/deals_screen.dart';
import '../discover/discover_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../wallet/wallet_screen.dart';

/// Main shell — role-aware navigation.
class MainShell extends StatelessWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: FirestoreService.instance.streamUser(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text('User not found. Please sign in again.'),
            ),
          );
        }

        // Role-based routing
        if (user.isModerator) {
          return _AdminView(user: user);
        }
        if (user.isBusiness) {
          return const _BusinessShell();
        }
        if (user.isAgency) {
          return _AgencyView(user: user);
        }
        // Default: customer
        return _CustomerShell(initialIndex: initialIndex);
      },
    );
  }
}

// ============================================================
// CUSTOMER SHELL (default — 5 tabs)
// ============================================================
class _CustomerShell extends StatefulWidget {
  final int initialIndex;

  const _CustomerShell({this.initialIndex = 0});

  @override
  State<_CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<_CustomerShell> {
  late int _index;

  static const _screens = <Widget>[
    HomeScreen(),
    DiscoverScreen(),
    DealsScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            body: IndexedStack(index: _index, children: _screens),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: isAr ? 'الرئيسية' : 'Home',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.explore_outlined),
                  selectedIcon: const Icon(Icons.explore),
                  label: isAr ? 'اكتشف' : 'Discover',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.local_offer_outlined),
                  selectedIcon: const Icon(Icons.local_offer),
                  label: isAr ? 'العروض' : 'Deals',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: const Icon(Icons.account_balance_wallet),
                  label: isAr ? 'المحفظة' : 'Wallet',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: isAr ? 'الملف' : 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// BUSINESS SHELL (2 tabs: My Business + Profile)
// ============================================================
class _BusinessShell extends StatefulWidget {
  const _BusinessShell();

  @override
  State<_BusinessShell> createState() => _BusinessShellState();
}

class _BusinessShellState extends State<_BusinessShell> {
  int _index = 0;

  static const _screens = <Widget>[
    MyBusinessScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            body: IndexedStack(index: _index, children: _screens),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.storefront_outlined),
                  selectedIcon: const Icon(Icons.storefront),
                  label: isAr ? 'عملي' : 'My Business',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: isAr ? 'الملف' : 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// ADMIN VIEW (mobile)
// ============================================================
class _AdminView extends StatelessWidget {
  const _AdminView({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final isAr = LocaleProvider.instance.locale == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: MigoGradients.heroBlue),
          child: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 100,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isAr ? 'دخول المسؤول' : 'Admin Access',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAr
                              ? 'تم تسجيل الدخول كـ ${user.roleLabel}'
                              : 'Signed in as ${user.roleLabel}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.open_in_new,
                                size: 32,
                                color: MigoColors.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isAr ? 'لوحة المسؤول' : 'Admin Panel',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: MigoColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isAr
                                    ? 'استخدم لوحة المسؤول على الويب لإدارة MIGO:'
                                    : 'Use the web admin panel to manage MIGO:',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: MigoColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: MigoColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'migo-app-3030e.web.app',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: MigoColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          isAr
                              ? 'تم تحسين تطبيق الهاتف للعملاء وأصحاب الأعمال.\n'
                                  'لمهام المسؤول، يرجى استخدام متصفح سطح المكتب.'
                              : 'The mobile app is optimized for customers and business owners.\n'
                                  'For admin tasks, please use a desktop browser.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// AGENCY VIEW (mobile — placeholder)
// ============================================================
class _AgencyView extends StatelessWidget {
  const _AgencyView({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final isAr = LocaleProvider.instance.locale == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'لوحة الوكالة' : 'Agency Dashboard'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: MigoColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.business_center,
                    size: 64,
                    color: MigoColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isAr ? 'دخول الوكالة' : 'Agency Access',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: MigoColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr
                      ? 'مرحبًا، ${user.displayName ?? user.email}'
                      : 'Welcome, ${user.displayName ?? user.email}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: MigoColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: MigoColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: MigoColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.construction, color: MigoColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'لوحة الوكالة قادمة قريباً (المرحلة B3).\n'
                                  'ستتمكن من إدارة أعمال منطقتك هنا.'
                              : 'Agency dashboard coming soon (Phase B3).\n'
                                  'You will be able to manage your area\'s businesses here.',
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}