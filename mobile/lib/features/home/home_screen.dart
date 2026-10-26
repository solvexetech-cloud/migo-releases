import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import '../../core/theme/migo_gradients.dart';
import '../../core/theme/migo_shadows.dart';
import '../../core/utils/migo_animations.dart';
import '../../models/area_model.dart';
import '../../models/category_model.dart';
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
  String _selectedIntention = 'All';
  AreaModel? _currentArea;
  String _userCountry = 'QA';
  bool _loadingArea = true;

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
      
      // യൂസറുടെ രാജ്യം ശരിയായ കോഡിലേക്ക് മാറ്റുന്നു
      String rawCountry = user?.country ?? 'QA';
      String finalCountry = 'QA';
      if (rawCountry.toLowerCase().contains('qatar')) {
        finalCountry = 'QA';
      } else if (rawCountry.toLowerCase().contains('india')) {
        finalCountry = 'IN';
      } else if (rawCountry.toLowerCase().contains('uae') || rawCountry.toLowerCase().contains('emirates')) {
        finalCountry = 'AE';
      } else if (rawCountry.toLowerCase().contains('saudi')) {
        finalCountry = 'SA';
      } else if (rawCountry.toLowerCase().contains('kuwait')) {
        finalCountry = 'KW';
      } else if (rawCountry.toLowerCase().contains('oman')) {
        finalCountry = 'OM';
      } else if (rawCountry.toLowerCase().contains('bahrain')) {
        finalCountry = 'BH';
      } else if (rawCountry.length > 2) {
        finalCountry = rawCountry.substring(0, 2).toUpperCase();
      } else {
        finalCountry = rawCountry.toUpperCase();
      }

      setState(() {
        _currentArea = area;
        _userCountry = finalCountry;
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

    // ഏരിയയുടെ രാജ്യം കണ്ടെത്തുന്നു
    String newCountryCode = 'QA';
    if (selected.zoneSlug.isNotEmpty) {
      if (selected.zoneSlug.contains('dubai') || 
          selected.zoneSlug.contains('abu-dhabi') || 
          selected.zoneSlug.contains('sharjah')) {
        newCountryCode = 'AE';
      } else if (selected.zoneSlug.contains('riyadh') || 
                 selected.zoneSlug.contains('jeddah') || 
                 selected.zoneSlug.contains('dammam')) {
        newCountryCode = 'SA';
      } else if (selected.zoneSlug.contains('kuwait')) {
        newCountryCode = 'KW';
      } else if (selected.zoneSlug.contains('muscat') || 
                 selected.zoneSlug.contains('salalah')) {
        newCountryCode = 'OM';
      } else if (selected.zoneSlug.contains('manama') || 
                 selected.zoneSlug.contains('muharraq')) {
        newCountryCode = 'BH';
      } else if (selected.zoneSlug.contains('kerala') || 
                 selected.zoneSlug.contains('mumbai') || 
                 selected.zoneSlug.contains('delhi') || 
                 selected.zoneSlug.contains('bangalore') || 
                 selected.zoneSlug.contains('chennai') ||
                 selected.zoneSlug.contains('ernakulam') ||
                 selected.zoneSlug.contains('thiruvananthapuram') ||
                 selected.zoneSlug.contains('kozhikode') ||
                 selected.zoneSlug.contains('thrissur')) {
        newCountryCode = 'IN';
      }
    }

    await LocationService.instance.saveSelectedArea(
      uid: uid,
      areaId: selected.id,
      countryCode: newCountryCode,
    );

    if (!mounted) return;
    setState(() {
      _currentArea = selected;
      _userCountry = newCountryCode;
    });
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isAr = LocaleProvider.instance.locale == 'ar';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAr ? 'اختر لغتك' : 'Choose your language',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Text('🇸🇦', style: TextStyle(fontSize: 26)),
                  title: const Text('العربية (Arabic)', style: TextStyle(fontWeight: FontWeight.w800)),
                  trailing: isAr ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await LocaleProvider.instance.setLocale('ar');
                  },
                ),
                ListTile(
                  leading: const Text('🇬🇧', style: TextStyle(fontSize: 26)),
                  title: const Text('English', style: TextStyle(fontWeight: FontWeight.w800)),
                  trailing: !isAr ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await LocaleProvider.instance.setLocale('en');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String get _selectedCategoryFilter {
    if (_selectedIntention == 'All' || _selectedIntention == 'الكل') return 'all';
    return _selectedIntention.toLowerCase();
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
            body: CustomScrollView(
              slivers: [
                // ---------- HERO HEADER ----------
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: MigoGradients.heroBlue,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isAr ? 'ميجو' : AppConfig.appName,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: isAr ? 0 : 3,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: _LocationChip(
                                    loading: _loadingArea,
                                    areaName: _currentArea?.name,
                                    onTap: _changeLocation,
                                    isAr: isAr,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.language, color: Colors.white),
                                  onPressed: _showLanguagePicker,
                                ),

                                const Spacer(),
                                IconButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const NotificationsScreen(),
                                      ),
                                    );
                                  },
                                  icon: StreamBuilder<int>(
                                    stream: FirestoreService.instance
                                        .streamUnreadNotificationCount(
                                      FirebaseAuth.instance.currentUser?.uid ?? '',
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
                                            right: isAr ? null : -4,
                                            left: isAr ? -4 : null,
                                            top: -4,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 5,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: MigoColors.error,
                                                borderRadius: BorderRadius.circular(10),
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
                            const SizedBox(height: 20),
                            Text(
                              isAr
                                  ? 'ماذا يمكنك أن تكتشف\nأو توفره اليوم؟'
                                  : 'What can you discover\nor save today?',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            MigoGoldButton(
                              label: isAr ? 'اختر لي' : 'Pick For Me',
                              icon: Icons.auto_awesome,
                              onPressed: () => PickForMeSheet.show(context),
                            ),
                            const SizedBox(height: 12),
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
                                  hintText: isAr
                                      ? 'ابحث عن الأعمال، العروض، المأكولات...'
                                      : 'Search businesses, deals, cuisines...',
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
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
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

                // Store Flyers Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MagazineScreen()),
                        );
                      },
                      child: Container(
                        height: 65,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [MigoColors.primary, MigoColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: MigoColors.accent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.local_offer,
                                  color: Colors.black,
                                  size: 20,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr ? 'منشورات المتاجر' : 'Store Flyers',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isAr
                                        ? 'استكشف أحدث عروض المتاجر'
                                        : 'Explore latest store offers',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(
                                isAr ? Icons.chevron_left : Icons.chevron_right,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ---------- DYNAMIC CATEGORIES ----------
                SliverToBoxAdapter(
                  child: Container(
                    color: MigoColors.backgroundLight,
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                    child: SizedBox(
                      height: 45,
                      child: StreamBuilder<List<CategoryModel>>(
                        stream: FirestoreService.instance.streamCategories(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final categories = snapshot.data!;
                          
                          final allCategories = [
                            CategoryModel(
                              id: 'all',
                              name: isAr ? 'الكل' : 'All',
                              icon: 'apps',
                              order: 0,
                              active: true,
                            ),
                            ...categories
                          ];

                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: allCategories.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final cat = allCategories[i];
                              return IntentionChip(
                                label: cat.name,
                                icon: _getIconForCategory(cat.icon),
                                selected: _selectedIntention == cat.name,
                                onTap: () => setState(() => _selectedIntention = cat.name),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // ---------- FLASH DEALS ----------
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SectionHeader(
                      title: isAr ? '⚡ عروض سريعة' : '⚡ Flash Deals',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FlashDealsRow(
  areaId: _currentArea?.id, // ഏരിയ ഐഡി കൈമാറുന്നു
  categoryFilter: _selectedCategoryFilter,
  countryCode: _userCountry,
  isAr: isAr,
),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // ---------- NEARBY DEALS ----------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SectionHeader(
                      title: isAr ? 'عروض قريبة' : 'Nearby Deals',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _NearbyDealsRow(
  areaId: _currentArea?.id, // ഏരിയ ഐഡി കൈമാറുന്നു
  categoryFilter: _selectedCategoryFilter,
  countryCode: _userCountry,
  isAr: isAr,
),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForCategory(String iconKey) {
    switch (iconKey) {
      case 'restaurant_outlined':
        return Icons.restaurant_outlined;
      case 'local_cafe_outlined':
        return Icons.local_cafe_outlined;
      case 'family_restroom_outlined':
        return Icons.family_restroom_outlined;
      case 'savings_outlined':
        return Icons.savings_outlined;
      case 'celebration_outlined':
        return Icons.celebration_outlined;
      case 'shopping_bag_outlined':
        return Icons.shopping_bag_outlined;
      case 'spa_outlined':
        return Icons.spa_outlined;
      case 'build_outlined':
        return Icons.build_outlined;
      case 'explore_outlined':
        return Icons.explore_outlined;
      default:
        return Icons.local_offer_outlined;
    }
  }
}

// ---------- LOCATION CHIP ----------
class _LocationChip extends StatelessWidget {
  const _LocationChip({
    required this.loading,
    required this.areaName,
    required this.onTap,
    required this.isAr,
  });

  final bool loading;
  final String? areaName;
  final VoidCallback onTap;
  final bool isAr;

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
    final displayText = hasArea
        ? areaName!
        : (isAr ? 'تحديد الموقع' : 'Set location');
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
  const _FlashDealsRow({
    this.areaId,
    this.categoryFilter,
    this.countryCode,
    required this.isAr,
  });
  final String? areaId;
  final String? categoryFilter;
  final String? countryCode;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final stream = areaId != null
        ? FirestoreService.instance.streamLiveOffersByAreaAndType(
            areaId!,
            'flash',
            countryCode: countryCode,
          )
        : FirestoreService.instance.streamLiveOffersByType(
            'flash',
            countryCode: countryCode,
          );

    return StreamBuilder<List<OfferModel>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 2,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => const ShimmerBox(width: 200, height: 230, radius: 16),
            ),
          );
        }
        
        var offers = snap.data ?? [];
        
        if (categoryFilter != null && categoryFilter != 'all') {
          offers = offers.where((o) => o.category.toLowerCase().contains(categoryFilter!.toLowerCase())).toList();
        }

        if (offers.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                isAr ? 'لا توجد عروض سريعة في منطقتك' : 'No flash deals in your area',
                style: const TextStyle(color: MigoColors.textSecondaryLight),
              ),
            ),
          );
        }
        return SizedBox(
          height: 230,
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
  const _NearbyDealsRow({
    this.areaId,
    this.categoryFilter,
    this.countryCode,
    required this.isAr,
  });
  final String? areaId;
  final String? categoryFilter;
  final String? countryCode;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final stream = areaId != null
        ? FirestoreService.instance.streamLiveOffersByArea(
            areaId!,
            countryCode: countryCode,
          )
        : FirestoreService.instance.streamLiveOffers(
            limit: 10,
            countryCode: countryCode,
          );

    return StreamBuilder<List<OfferModel>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 300,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 2,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => const SizedBox(
                width: 280,
                child: ShimmerBox(height: 300, radius: 18),
              ),
            ),
          );
        }
        
        var offers = snap.data ?? [];
        
        if (categoryFilter != null && categoryFilter != 'all') {
          offers = offers.where((o) => o.category.toLowerCase().contains(categoryFilter!.toLowerCase())).toList();
        }

        if (offers.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: MigoColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MigoColors.dividerLight),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  size: 48,
                  color: MigoColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  isAr ? 'لا توجد عروض في منطقتك' : 'No offers in your area',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MigoColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr ? 'تغيير الموقع أو التحقق مرة أخرى قريبا.' : 'Change location or check back soon.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: MigoColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          );
        }
        return SizedBox(
          height: 300,
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