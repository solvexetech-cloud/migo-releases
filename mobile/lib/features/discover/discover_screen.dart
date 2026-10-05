import 'package:flutter/material.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/offer_model.dart';
import '../../services/firestore_service.dart';
import '../../core/utils/migo_animations.dart';
import '../../widgets/migo_empty_state.dart';
import '../deals/offer_detail_screen.dart';

enum SortMode { newest, bestSavings, expiringSoon }

extension SortModeX on SortMode {
  String get label {
    switch (this) {
      case SortMode.newest:
        return 'Newest';
      case SortMode.bestSavings:
        return 'Best savings';
      case SortMode.expiringSoon:
        return 'Expiring soon';
    }
  }
}

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _category;
  SortMode _sort = SortMode.newest;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  static const _categories = [
    'Food',
    'Beauty',
    'Auto',
    'Events',
    'Photography',
    'Fitness',
    'Shopping',
    'Education',
    'Home Services',
  ];

  @override
  void dispose() {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search deals, businesses, cuisines...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: MigoColors.surfaceLight,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _CategoryPill(
                              label: 'All',
                              selected: _category == null,
                              onTap: () =>
                                  setState(() => _category = null),
                            ),
                            const SizedBox(width: 6),
                            ..._categories.map((c) => Padding(
                                  padding:
                                      const EdgeInsets.only(right: 6),
                                  child: _CategoryPill(
                                    label: c,
                                    selected: _category == c,
                                    onTap: () => setState(
                                      () => _category =
                                          _category == c ? null : c,
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
                                child: Text(s.label),
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

          if (filtered.isEmpty) {
            final hasFilters = _query.isNotEmpty || _category != null;
            return MigoEmptyState(
              icon: hasFilters
                  ? Icons.search_off
                  : Icons.explore_outlined,
              title: hasFilters
                  ? 'No offers match your filters'
                  : 'No offers yet',
              body: hasFilters
                  ? 'Try a different search or category.'
                  : 'Check back soon for new deals.',
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} '
                      '${filtered.length == 1 ? "offer" : "offers"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: MigoColors.textSecondaryLight,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Sort: ${_sort.label}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: MigoColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
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
                ),
              ),
            ],
          );
        },
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

class _OfferTile extends StatelessWidget {
  const _OfferTile({required this.offer, required this.onTap});

  final OfferModel offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: MigoColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MigoColors.dividerLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: MigoColors.primary.withValues(alpha: 0.08),
                  child: offer.imageUrl == null
                      ? const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 32,
                            color: MigoColors.primary,
                          ),
                        )
                      : Image.network(offer.imageUrl!, fit: BoxFit.cover),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.businessName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: MigoColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
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
                    const SizedBox(height: 6),
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
                        'SAVE ${offer.currency} ${offer.savings.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: MigoColors.success,
                        ),
                      ),
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