import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/offer_model.dart';
import '../../services/firestore_service.dart';
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

            // Pick For Me
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
                    icon: const Icon(
                      Icons.auto_awesome,
                      color: MigoColors.accent,
                    ),
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

            // Search
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
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
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

            // Flash Deals（real data）
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(title: '⚡ Flash Deals'),
              ),
            ),
            SliverToBoxAdapter(
              child: _FlashDealsRow(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Nearby Deals（real data）
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(title: 'Nearby Deals'),
              ),
            ),
            SliverToBoxAdapter(
              child: _NearbyDealsRow(),
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

class _FlashDealsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OfferModel>>(
      stream: FirestoreService.instance.streamLiveOffersByType('flash'),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
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
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: offers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => FlashDealCard(offer: offers[i]),
          ),
        );
      },
    );
  }
}

class _NearbyDealsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OfferModel>>(
      stream: FirestoreService.instance.streamLiveOffers(limit: 10),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 360,
            child: Center(child: CircularProgressIndicator()),
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
          height: 360,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: offers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: 280,
              child: OfferCard(offer: offers[i]),
            ),
          ),
        );
      },
    );
  }
}