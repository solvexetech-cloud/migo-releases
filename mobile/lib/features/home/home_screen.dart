import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/migo_colors.dart';
import '../../core/theme/migo_gradients.dart';
import '../../core/theme/migo_shadows.dart';
import '../../core/utils/migo_animations.dart';
import '../../models/offer_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/category_grid.dart';
import '../../widgets/flash_deal_card.dart';
import '../../widgets/intention_chip.dart';
import '../../widgets/migo_gold_button.dart';
import '../../widgets/offer_card.dart';
import '../../widgets/pick_for_me_sheet.dart';
import '../../widgets/section_header.dart';
import '../deals/offer_detail_screen.dart';
import '../discover/discover_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedIntention = 'Eat';

  static const _intentions = <({String label, IconData icon})>[
    (label: 'Eat', icon: Icons.restaurant_outlined),
    (label: 'Coffee', icon: Icons.local_cafe_outlined),
    (label: 'Family', icon: Icons.family_restroom_outlined),
    (label: 'Save Money', icon: Icons.savings_outlined),
    (label: 'Celebrate', icon: Icons.celebration_outlined),
    (label: 'Shop', icon: Icons.shopping_bag_outlined),
    (label: 'Relax', icon: Icons.spa_outlined),
    (label: 'Service', icon: Icons.build_outlined),
    (label: 'Explore', icon: Icons.explore_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ---------- HERO HEADER ----------
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: MigoGradients.heroBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: MIGO + location + bell
                      Row(
                        children: [
                          const Text(
                            AppConfig.appName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.place,
                                  size: 12,
                                  color: MigoColors.accent,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Doha',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const NotificationsScreen(),
                                ),
                              );
                            },
                            icon: StreamBuilder<int>(
                              stream: FirestoreService.instance
                                  .streamUnreadNotificationCount(
                                FirebaseAuth
                                        .instance.currentUser?.uid ??
                                    '',
                              ),
                              builder: (context, snap) {
                                final count = snap.data ?? 0;
                                if (count == 0) {
                                  return const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                  );
                                }
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                    ),
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: MigoColors.error,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          count > 9 ? '9+' : '$count',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      // Headline
                      const Text(
                        'What can you discover\nor save today?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.25,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Pick For Me
                      MigoGoldButton(
                        label: 'Pick For Me',
                        icon: Icons.auto_awesome,
                        onPressed: () => PickForMeSheet.show(context),
                      ),
                      const SizedBox(height: 14),
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: MigoShadows.soft,
                        ),
                        child: TextField(
                          readOnly: true,
                          onTap: () {},
                          decoration: InputDecoration(
                            hintText:
                                'Search businesses, deals, cuisines...',
                            hintStyle: const TextStyle(
                              color: MigoColors.textSecondaryLight,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: MigoColors.primary,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ---------- INTENTION CHIPS (height 52, was 42) ----------
          SliverToBoxAdapter(
            child: Container(
              color: MigoColors.backgroundLight,
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
              child: SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _intentions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final item = _intentions[i];
                    return IntentionChip(
                      label: item.label,
                      icon: item.icon,
                      selected: _selectedIntention == item.label,
                      onTap: () => setState(
                        () => _selectedIntention = item.label,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ---------- FLASH DEALS ----------
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(title: '⚡ Flash Deals'),
            ),
          ),
          const SliverToBoxAdapter(child: _FlashDealsRow()),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ---------- NEARBY DEALS ----------
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(title: 'Nearby Deals'),
            ),
          ),
          const SliverToBoxAdapter(child: _NearbyDealsRow()),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // ---------- CATEGORIES (with See all + tap callback) ----------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(
                title: 'Browse Categories',
                actionLabel: 'See all',
                onActionTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DiscoverScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(
            child: CategoryGrid(
              maxItems: 6,
              onCategoryTap: (name) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DiscoverScreen(initialCategory: name),
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _FlashDealsRow extends StatelessWidget {
  const _FlashDealsRow();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OfferModel>>(
      stream: FirestoreService.instance.streamLiveOffersByType('flash'),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 2,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => const ShimmerBox(
                width: 220,
                height: 200,
                radius: 16,
              ),
            ),
          );
        }
        final offers = snap.data ?? [];
        if (offers.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'No flash deals right now',
                style: TextStyle(color: MigoColors.textSecondaryLight),
              ),
            ),
          );
        }
        return SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: offers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => TapScale(
              onTap: () {
                Navigator.of(context).push(
                  FadeSlideRoute(
                    child: OfferDetailScreen(offer: offers[i]),
                  ),
                );
              },
              child: FlashDealCard(offer: offers[i]),
            ),
          ),
        );
      },
    );
  }
}

class _NearbyDealsRow extends StatelessWidget {
  const _NearbyDealsRow();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OfferModel>>(
      stream: FirestoreService.instance.streamLiveOffers(limit: 10),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 400,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 2,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => const SizedBox(
                width: 280,
                child: ShimmerBox(height: 400, radius: 18),
              ),
            ),
          );
        }
        final offers = snap.data ?? [];
        if (offers.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: MigoColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MigoColors.dividerLight),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 48,
                  color: MigoColors.primary,
                ),
                SizedBox(height: 12),
                Text(
                  'No offers yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MigoColors.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Check back soon — new deals are on the way.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: MigoColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          );
        }
        return SizedBox(
          height: 400,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: offers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: 280,
              child: TapScale(
                onTap: () {
                  Navigator.of(context).push(
                    FadeSlideRoute(
                      child: OfferDetailScreen(offer: offers[i]),
                    ),
                  );
                },
                child: OfferCard(offer: offers[i]),
              ),
            ),
          ),
        );
      },
    );
  }
}