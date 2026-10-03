import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/migo_colors.dart';
import '../../widgets/category_grid.dart';
import '../../widgets/flash_deal_card.dart';
import '../../widgets/intention_chip.dart';
import '../../widgets/offer_card.dart';
import '../../widgets/pick_for_me_sheet.dart';
import '../../widgets/section_header.dart';

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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      AppConfig.appName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            color: MigoColors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.place,
                      size: 16,
                      color: MigoColors.primary,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Doha, Qatar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MigoColors.textPrimaryLight,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: MigoColors.textSecondaryLight,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_outlined),
                    ),
                  ],
                ),
              ),
            ),

            // Greeting
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  'What can you discover or save today?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: MigoColors.textPrimaryLight,
                  ),
                ),
              ),
            ),

            // Pick For Me button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => PickForMeSheet.show(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MigoColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.auto_awesome, color: MigoColors.accent),
                    label: const Text(
                      'Pick For Me',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: TextField(
                  readOnly: true,
                  onTap: () {},
                  decoration: InputDecoration(
                    hintText: 'Search businesses, deals, cuisines...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: MigoColors.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

            // Intention chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
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

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Flash Deals
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(
                  title: '⚡ Flash Deals',
                  actionLabel: 'See all',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 3,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final samples = [
                      (
                        business: 'Shawarma Station',
                        title: 'Chicken Shawarma Combo',
                        original: 25.0,
                        offer: 15.0,
                        time: '45m left',
                      ),
                      (
                        business: 'Karak House',
                        title: 'Karak + Snack Box',
                        original: 18.0,
                        offer: 10.0,
                        time: '1h 20m left',
                      ),
                      (
                        business: 'Burger Bros',
                        title: 'Double Burger Meal',
                        original: 55.0,
                        offer: 32.0,
                        time: '2h left',
                      ),
                    ];
                    final s = samples[i];
                    return FlashDealCard(
                      businessName: s.business,
                      title: s.title,
                      originalPrice: s.original,
                      offerPrice: s.offer,
                      currency: AppConfig.defaultCurrency,
                      timeLeft: s.time,
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Nearby Deals
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(
                  title: 'Nearby Deals',
                  actionLabel: 'See all',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 360,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 3,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final samples = [
                      (
                        business: 'Karak House',
                        title: 'Family Meal Deal',
                        original: 42.0,
                        offer: 35.0,
                        distance: 1.8,
                        time: 'Ends in 2h 15m',
                        verified: 92,
                      ),
                      (
                        business: 'Shawarma Station',
                        title: 'Chicken Shawarma Combo',
                        original: 25.0,
                        offer: 18.0,
                        distance: 0.9,
                        time: 'Ends in 45m',
                        verified: 88,
                      ),
                      (
                        business: 'Cafe Mocha',
                        title: 'Breakfast for Two',
                        original: 60.0,
                        offer: 45.0,
                        distance: 2.4,
                        time: null,
                        verified: 95,
                      ),
                    ];
                    final s = samples[i];
                    return SizedBox(
                      width: 280,
                      child: OfferCard(
                        businessName: s.business,
                        title: s.title,
                        originalPrice: s.original,
                        offerPrice: s.offer,
                        currency: AppConfig.defaultCurrency,
                        distanceKm: s.distance,
                        timeLeft: s.time,
                        verifiedPercent: s.verified,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Categories
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(title: 'Browse Categories'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            const SliverToBoxAdapter(child: CategoryGrid()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}