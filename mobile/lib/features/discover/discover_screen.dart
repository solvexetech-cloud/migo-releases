import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/localization/locale_provider.dart';
import '../../services/analytics_service.dart';
import '../../core/theme/migo_colors.dart';
import '../../core/utils/migo_animations.dart';
import '../../models/area_model.dart';
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
      list = list.where((o) => o.category == _category).toList();
    }

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              title: Text(isAr ? 'اكتشف' : 'Discover', style: const TextStyle(fontWeight: FontWeight.w800)),
              backgroundColor: Colors.white,
              elevation: 0,
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
                preferredSize: const Size.fromHeight(120),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                              ? 'ابحث عن العروض، الشركات...'
                              : 'Search deals, businesses...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _CategoryPill(
                                    label: isAr ? 'الكل' : 'All',
                                    selected: _category == null,
                                    onTap: () => setState(() => _category = null),
                                  ),
                                  const SizedBox(width: 8),
                                  ..._categories.map((c) => Padding(
                                        padding: const EdgeInsets.only(right: 8),
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
                            icon: const Icon(Icons.sort, size: 20),
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
              stream: _areaId != null
                  ? FirestoreService.instance.streamLiveOffersByArea(_areaId!)
                  : FirestoreService.instance.streamLiveOffers(limit: 50),
              builder: (context, snap) {
                                  if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data ?? [];
                final filtered = _applyFilters(all);

                return CustomScrollView(
                  slivers: [
                    // Community Demands Card
                    SliverToBoxAdapter(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DemandsFeedScreen()),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
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
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAr ? 'طلبات المجتمع' : 'Community Demands',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isAr
                                          ? 'اطلب منتجك ودع المتاجر تتنافس على أفضل سعر.'
                                          : 'Request a product & let shops bid.',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
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

                    // Offer Count
                    if (filtered.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Text(
                                '${filtered.length} ${isAr ? 'عرض' : (filtered.length == 1 ? "offer" : "offers")}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const Spacer(),
                              Text(
                                isAr ? 'ترتيب: ${_sort.label(isAr)}' : 'Sort: ${_sort.label(isAr)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Offers Grid or Empty State
                    if (filtered.isEmpty)
                      SliverFillRemaining(
                        child: MigoEmptyState(
                          icon: Icons.search_off,
                          title: isAr ? 'لا توجد عروض' : 'No offers found',
                          body: isAr ? 'جرب بحثًا آخر.' : 'Try a different search.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.68, // 🆕 ഉയരം കുറച്ചു
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final o = filtered[i];
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
          color: Colors.grey.shade100,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasArea ? MigoColors.primary.withValues(alpha: 0.1) : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hasArea ? MigoColors.primary.withValues(alpha: 0.3) : Colors.orange.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.place,
              size: 14,
              color: hasArea ? MigoColors.primary : Colors.orange.shade800,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                displayText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: hasArea ? MigoColors.primary : Colors.orange.shade800,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: hasArea ? MigoColors.primary : Colors.orange.shade800,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? MigoColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? MigoColors.primary : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.offer,
    required this.onTap,
    required this.isAr,
  });

  final OfferModel offer;
  final VoidCallback onTap;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Container(
                      color: Colors.grey.shade100,
                      child: offer.imageUrl == null
                          ? const Center(child: Icon(Icons.image_outlined, size: 32, color: Colors.grey))
                          : Image.network(offer.imageUrl!, fit: BoxFit.cover),
                    ),
                  ),
                ),
                // Category Tag
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      offer.category,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
            
            // Details Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.businessName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        offer.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Price Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${offer.currency} ${offer.offerPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: MigoColors.primary,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${offer.currency} ${offer.originalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Save Badge & Rating Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isAr
                                ? 'وفر ${offer.currency} ${offer.savings.toStringAsFixed(0)}'
                                : 'SAVE ${offer.currency} ${offer.savings.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                        // 🆕 Rating Star (Dummy for now)
                        Row(
                          children: [
                            const Icon(Icons.star, size: 12, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              '5.0',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
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