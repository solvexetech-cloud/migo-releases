import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
///
/// Routes users based on their role:
/// - customer → Home/Discover/Deals/Wallet/Profile (default)
/// - business → Business dashboard
/// - moderator/admin/super_admin → Admin view (opens admin web panel)
/// - agency → Agency view (placeholder — B3)
class MainShell extends StatelessWidget {
  const MainShell({super.key});

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
        // Loading
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
        return const _CustomerShell();
      },
    );
  }
}

// ============================================================
// CUSTOMER SHELL (default — 5 tabs)
// ============================================================
class _CustomerShell extends StatefulWidget {
  const _CustomerShell();

  @override
  State<_CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<_CustomerShell> {
  int _index = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    DiscoverScreen(),
    DealsScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer),
            label: 'Deals',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
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
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'My Business',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
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
    return Scaffold(
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
                  const Text(
                    'Admin Access',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Signed in as ${user.roleLabel}',
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
                        const Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: MigoColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Use the web admin panel to manage MIGO:',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
                    'The mobile app is optimized for customers and business owners.\n'
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agency Dashboard'),
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
              const Text(
                'Agency Access',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: MigoColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome, ${user.displayName ?? user.email}',
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
                child: const Row(
                  children: [
                    Icon(Icons.construction, color: MigoColors.warning),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Agency dashboard coming soon (Phase B3).\n'
                        'You will be able to manage your area\'s businesses here.',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}