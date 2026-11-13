// mobile/lib/features/discover/discover_screen.dart
// TIGHT SPACING, GOLDEN BORDER FOR DEMANDS, SOFT BORDER FOR OFFERS
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/localization/locale_provider.dart';
import '../../services/analytics_service.dart';
import '../../core/theme/migo_colors.dart';
import '../../core/utils/migo_animations.dart';
import '../../models/offer_model.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../widgets/location_picker_modal.dart';
import '../../widgets/migo_empty_state.dart';
import '../deals/offer_detail_screen.dart';
import '../demands/demands_feed_screen.dart';

enum SortMode { newest, bestSavings, expiringSoon }

extension SortModeX on SortMode {
  String label(bool isAr) {
    switch (this) {
      case SortMode.newest:
        return isAr ? 'الأحدث' : 'Newest';
      case SortMode.bestSavings:
        return isAr ? 'أفضل التوفير' : 'Best savings';
      case SortMode.expiringSoon:
        return isAr ? 'تنتهي قريبًا' : 'Expiring soon';
    }
  }
}

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    this.initialCategory,
    this.initialArea,
  });

  final String? initialCategory;
  final String? initialArea;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  Timer? _searchDebounce;
  String? _category;
  String? _areaId;
  String? _areaName;
  SortMode _sort = SortMode.newest;
  
  String? _dealType;

  List<String> _categories = [];
  bool _autoDetecting = true;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _areaId = widget.initialArea;
    _loadCategories();
    _autoDetectArea();
  }

  Future<void> _autoDetectArea() async {
    if (widget.initialArea != null) {
      setState(() => _autoDetecting = false);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _autoDetecting = false);
      return;
    }

    try {
      final user = await FirestoreService.instance.getUser(uid);
      final area = await LocationService.instance.getDefaultArea(user);
      if (!mounted) return;
      setState(() {
        if (area != null) {
          _areaId = area.id;
          _areaName = area.name;
        }
        _autoDetecting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _autoDetecting = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await FirestoreService.instance.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats.map((c) => c.name).toList();
      });
    } catch (_) {}
  }

  Future<void> _changeLocation() async {
    final selected = await LocationPickerModal.show(context);
    if (selected == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await LocationService.instance.saveSelectedArea(
      uid: uid,
      areaId: selected.id,
      countryCode: 'QA',
    );

    if (!mounted) return;
    setState(() {
      _areaId = selected.id;
      _areaName = selected.name;
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<OfferModel> _applyFilters(List<OfferModel> input) {
    var list = input;

    if (_category != null) {
      final selectedCat = _category!.toLowerCase().trim();
      list = list.where((o) {
        final offerCat = o.category.toLowerCase().trim();
        return offerCat == selectedCat;
      }).toList();
    }

    if (_dealType != null) {
      list = list.where((o) {
        if (_dealType == 'flash') return o.type == OfferType.flash;
        if (_dealType == 'standard') return o.type == OfferType.standard;
        if (_dealType == 'group') return o.type == OfferType.group || o.type == OfferType.groupAllOrNothing || o.type == OfferType.groupProgressive;
        if (_dealType == 'reserve') return o.reserveEnabled == true;
        return true;
      }).toList();
    }

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase().trim();
      list = list
          .where((o) =>
              o.title.toLowerCase().contains(q) ||
              o.businessName.toLowerCase().contains(q) ||
              o.description.toLowerCase().contains(q))
          .toList();
    }

    final sorted = List<OfferModel>.from(list);
    switch (_sort) {
      case SortMode.newest:
        sorted.sort((a, b) {
          final ad = a.createdAt ?? DateTime(2000);
          final bd = b.createdAt ?? DateTime(2000);
          return bd.compareTo(ad);
        });
      case SortMode.bestSavings:
        sorted.sort((a, b) => b.savings.compareTo(a.savings));
      case SortMode.expiringSoon:
        sorted.sort((a, b) => a.endAt.compareTo(b.endAt));
    }
    return sorted;
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
            appBar: AppBar(
              title: Text(isAr ? 'اكتشف' : 'Discover'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _LocationChip(
                    areaName: _areaName,
                    loading: _autoDetecting,
                    onTap: _changeLocation,
                    isAr: isAr,
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(100), // 🆕 ഉയരം കുറച്ചു
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (v) {
                          setState(() => _query = v);
                          _searchDebounce?.cancel();
                          _searchDebounce = Timer(
                            const Duration(milliseconds: 1500),
                            () {
                              if (v.trim().isNotEmpty) {
                                AnalyticsService.instance.logSearch(query: v.trim());
                              }
                            },
                          );
                        },
                        decoration: InputDecoration(
                          hintText: isAr
                              ? 'ابحث عن العروض...'
                              : 'Search deals, businesses...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: MigoColors.surfaceLight,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10), // 🆕 ഉയരം കുറച്ചു
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8), // 🆕 സ്പേസ് കുറച്ചു
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 34, // 🆕 ഉയരം കുറച്ചു
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _CategoryPill(
                                    label: isAr ? 'الكل' : 'All',
                                    selected: _category == null,
                                    onTap: () => setState(() => _category = null),
                                  ),
                                  const SizedBox(width: 6),
                                  ..._categories.map((c) => Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: _CategoryPill(
                                          label: c,
                                          selected: _category == c,
                                          onTap: () => setState(
                                            () => _category = _category == c ? null : c,
                                          ),
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<SortMode>(
                            initialValue: _sort,
                            icon: const Icon(Icons.sort),
                            onSelected: (v) => setState(() => _sort = v),
                            itemBuilder: (_) => SortMode.values
                                .map((s) => PopupMenuItem(
                                      value: s,
                                      child: Text(s.label(isAr)),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: StreamBuilder<List<OfferModel>>(
              stream: FirestoreService.instance.streamLiveOffers(limit: 50),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data ?? [];
                final filtered = _applyFilters(all);

                return CustomScrollView(
                  slivers: [
                    // 1️⃣ CUSTOMER DEMANDS (Golden Border + Tighter Margin)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), // 🆕 മാർജിൻ കുറച്ചു
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DemandsFeedScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              // 🆕 ഗോൾഡൻ ബോർഡർ
                              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 26),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isAr ? 'طلبات العملاء' : 'Customer Demands',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          _buildTag(isAr ? 'مجتمعي' : 'Community', Colors.white.withValues(alpha: 0.2)),
                                          const SizedBox(width: 6),
                                          _buildTag(isAr ? 'شخصي' : 'Personal', Colors.white.withValues(alpha: 0.2)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        isAr
                                            ? 'اطلب منتجك و دع المتاجر تتنافس على أفضل سعر.'
                                            : 'Request a product & let shops compete for your business.',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 2️⃣ DEAL TYPES (ബട്ടണുകൾ) - ഉയരം കുറച്ചു
                    SliverToBoxAdapter(
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _DealTypePill(
                              label: isAr ? 'الكل' : 'All Types',
                              icon: Icons.apps,
                              color: Colors.blueGrey,
                              selected: _dealType == null,
                              onTap: () => setState(() => _dealType = null),
                            ),
                            const SizedBox(width: 8),
                            _DealTypePill(
                              label: isAr ? 'فلاش' : 'Flash',
                              icon: Icons.flash_on,
                              color: Colors.red,
                              selected: _dealType == 'flash',
                              onTap: () => setState(() => _dealType = _dealType == 'flash' ? null : 'flash'),
                            ),
                            const SizedBox(width: 8),
                            _DealTypePill(
                              label: isAr ? 'قياسي' : 'Standard',
                              icon: Icons.local_offer,
                              color: Colors.blue,
                              selected: _dealType == 'standard',
                              onTap: () => setState(() => _dealType = _dealType == 'standard' ? null : 'standard'),
                            ),
                            const SizedBox(width: 8),
                            _DealTypePill(
                              label: isAr ? 'جماعي' : 'Group',
                              icon: Icons.group,
                              color: Colors.purple,
                              selected: _dealType == 'group',
                              onTap: () => setState(() => _dealType = _dealType == 'group' ? null : 'group'),
                            ),
                            const SizedBox(width: 8),
                            _DealTypePill(
                              label: isAr ? 'حجز' : 'Reserve',
                              icon: Icons.event_available,
                              color: Colors.orange,
                              selected: _dealType == 'reserve',
                              onTap: () => setState(() => _dealType = _dealType == 'reserve' ? null : 'reserve'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3️⃣ OFFERS HEADER
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8), // 🆕 സ്പേസ് കുറച്ചു
                        child: Row(
                          children: [
                            Text(
                              isAr ? 'العروض' : 'Offers',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: MigoColors.textPrimaryLight,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${filtered.length} ${isAr ? 'عرض' : (filtered.length == 1 ? "offer" : "offers")}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: MigoColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 4️⃣ OFFERS GRID
                    if (filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: MigoEmptyState(
                          icon: Icons.explore_outlined,
                          title: isAr ? 'لا توجد عروض بعد' : 'No offers yet',
                          body: isAr ? 'تحقق مرة أخرى قريبًا.' : 'Check back soon for new deals.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final o = filtered[i];
                              return FutureBuilder<double>(
                                future: FirestoreService.instance.getAverageRating(o.businessId),
                                builder: (context, ratingSnap) {
                                  final rating = ratingSnap.data ?? 0.0;
                                  return TapScale(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        FadeSlideRoute(
                                          child: OfferDetailScreen(offer: o),
                                        ),
                                      );
                                    },
                                    child: _OfferTile(
                                      offer: o,
                                      rating: rating,
                                      isAr: isAr,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          FadeSlideRoute(
                                            child: OfferDetailScreen(offer: o),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: filtered.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ---------- LOCATION CHIP ----------
class _LocationChip extends StatelessWidget {
  const _LocationChip({
    required this.areaName,
    required this.loading,
    required this.onTap,
    required this.isAr,
  });

  final String? areaName;
  final bool loading;
  final VoidCallback onTap;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: MigoColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const SizedBox(
          width: 60,
          height: 12,
          child: Center(
            child: SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ),
        ),
      );
    }

    final hasArea = areaName != null && areaName!.isNotEmpty;
    final displayText = hasArea ? areaName! : (isAr ? 'تحديد الموقع' : 'Set location');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hasArea
              ? MigoColors.primary.withValues(alpha: 0.1)
              : MigoColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.place,
              size: 12,
              color: hasArea ? MigoColors.primary : MigoColors.warning,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                displayText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: hasArea ? MigoColors.primary : MigoColors.warning,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              size: 12,
              color: hasArea ? MigoColors.primary : MigoColors.warning,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? MigoColors.primary : MigoColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? MigoColors.primary : MigoColors.dividerLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : MigoColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }
}

class _DealTypePill extends StatelessWidget {
  const _DealTypePill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.3),
          ),
          boxShadow: selected ? [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : color,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.offer,
    required this.rating,
    required this.onTap,
    required this.isAr,
  });

  final OfferModel offer;
  final double rating;
  final VoidCallback onTap;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: MigoColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          // 🆕 സോഫ്റ്റ് ബോർഡർ (ആപ്പിന്റെ കളർ തീമിനോട് ചേരുന്നത്)
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Container(
                  color: MigoColors.primary.withValues(alpha: 0.08),
                  child: offer.imageUrl == null || offer.imageUrl!.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 32,
                            color: MigoColors.primary,
                          ),
                        )
                      : Image.network(
                          offer.imageUrl!, 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image, size: 32, color: Colors.grey),
                            );
                          },
                        ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.businessName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: MigoColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: Text(
                        offer.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: MigoColors.textPrimaryLight,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${offer.currency} ${offer.offerPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: MigoColors.primary,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${offer.currency} ${offer.originalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              color: MigoColors.textSecondaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: MigoColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isAr
                                ? 'وفر ${offer.currency} ${offer.savings.toStringAsFixed(0)}'
                                : 'SAVE ${offer.currency} ${offer.savings.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: MigoColors.success,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              rating > 0 ? Icons.star : Icons.star_border,
                              size: 12,
                              color: rating > 0 ? Colors.amber : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating > 0 ? rating.toStringAsFixed(1) : (isAr ? 'جديد' : 'New'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: rating > 0 ? Colors.grey.shade800 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}