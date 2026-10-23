import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/migo_colors.dart';
import '../../core/theme/migo_gradients.dart';
import '../../core/theme/migo_shadows.dart';
import '../../core/utils/migo_animations.dart';
import '../../models/area_model.dart';
import '../../models/offer_model.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../widgets/flash_deal_card.dart';
import '../../widgets/intention_chip.dart';
import '../../widgets/location_picker_modal.dart';
import '../../widgets/migo_gold_button.dart';
import '../../widgets/offer_card.dart';
import '../../widgets/pick_for_me_sheet.dart';
import '../../widgets/section_header.dart';
import '../deals/offer_detail_screen.dart';
import '../discover/discover_screen.dart';
import '../notifications/notifications_screen.dart';
import '../magazine/magazine_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedIntention = 'Eat';

  AreaModel? _currentArea;
  bool _loadingArea = true;

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
  void initState() {
    super.initState();
    _detectArea();
  }

  Future<void> _detectArea() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingArea = false);
      return;
    }

    try {
      final user = await FirestoreService.instance.getUser(uid);
      final area = await LocationService.instance.getDefaultArea(user);
      if (!mounted) return;
      setState(() {
        _currentArea = area;
        _loadingArea = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingArea = false);
    }
  }

  Future<void> _changeLocation() async {
    final selected = await LocationPickerModal.show(context);
    if (selected == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await LocationService.instance.saveSelectedArea(
      uid: uid,
      areaId: selected.id,
      countryCode: selected.zoneSlug.isNotEmpty
          ? (_currentArea?.zoneSlug ?? 'QA')
          : 'QA',
    );

    if (!mounted) return;
    setState(() => _currentArea = selected);
  }

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
                          Flexible(
                            child: _LocationChip(
                              loading: _loadingArea,
                              areaName: _currentArea?.name,
                              onTap: _changeLocation,
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
                      MigoGoldButton(
                        label: 'Pick For Me',
                        icon: Icons.auto_awesome,
                        onPressed: () => PickForMeSheet.show(context),
                      ),
                      const SizedBox(height: 14),
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

          // 🚀 MIGO Magazine Banner (ഒരു തവണ മാത്രം)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MagazineScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [MigoColors.primary, MigoColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: MigoColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: MigoColors.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.menu_book,
                            color: Colors.black,
                            size: 28,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MIGO Magazine',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Discover the latest flyers & deals!',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: Icon(
                          Icons.chevron_right,
                          color: MigoColors.accent,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ---------- INTENTION CHIPS ----------
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
          SliverToBoxAdapter(
            child: _FlashDealsRow(areaId: _currentArea?.id),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ---------- NEARBY DEALS ----------
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(title: 'Nearby Deals'),
            ),
          ),
          SliverToBoxAdapter(
            child: _NearbyDealsRow(areaId: _currentArea?.id),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // ---------- CATEGORIES (Horizontal Scroll) ----------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Browse Categories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DiscoverScreen(),
                              ),
                            );
                          },
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        final categories = [
                          {'name': 'Food', 'icon': Icons.restaurant},
                          {'name': 'Beauty', 'icon': Icons.spa},
                          {'name': 'Auto', 'icon': Icons.directions_car},
                          {'name': 'Events', 'icon': Icons.celebration},
                          {'name': 'Photo', 'icon': Icons.camera_alt},
                          {'name': 'Fitness', 'icon': Icons.fitness_center},
                        ];
                        final cat = categories[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DiscoverScreen(
                                  initialCategory: cat['name'] as String,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: MigoColors.primary
                                        .withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    cat['icon'] as IconData,
                                    color: MigoColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ---------- LOCATION CHIP ----------
class _LocationChip extends StatelessWidget {
  const _LocationChip({
    required this.loading,
    required this.areaName,
    required this.onTap,
  });

  final bool loading;
  final String? areaName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const SizedBox(
          width: 60,
          height: 12,
          child: Center(
            child: SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    final hasArea = areaName != null && areaName!.isNotEmpty;
    final displayText = hasArea ? areaName! : 'Set location';
    final bgColor = hasArea
        ? Colors.white.withValues(alpha: 0.18)
        : MigoColors.warning.withValues(alpha: 0.85);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasArea ? Icons.place : Icons.place_outlined,
              size: 12,
              color: hasArea ? MigoColors.accent : Colors.white,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                displayText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- FLASH DEALS ROW ----------
class _FlashDealsRow extends StatelessWidget {
  const _FlashDealsRow({this.areaId});
  final String? areaId;

  @override
  Widget build(BuildContext context) {
    final stream = areaId != null
        ? FirestoreService.instance
            .streamLiveOffersByAreaAndType(areaId!, 'flash')
        : FirestoreService.instance.streamLiveOffersByType('flash');

    return StreamBuilder<List<OfferModel>>(
      stream: stream,
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
                'No flash deals in your area',
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

// ---------- NEARBY DEALS ROW ----------
class _NearbyDealsRow extends StatelessWidget {
  const _NearbyDealsRow({this.areaId});
  final String? areaId;

  @override
  Widget build(BuildContext context) {
    final stream = areaId != null
        ? FirestoreService.instance.streamLiveOffersByArea(areaId!)
        : FirestoreService.instance.streamLiveOffers(limit: 10);

    return StreamBuilder<List<OfferModel>>(
      stream: stream,
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
                  'No offers in your area',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MigoColors.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Change location or check back soon.',
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