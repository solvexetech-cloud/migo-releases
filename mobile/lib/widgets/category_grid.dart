import 'package:flutter/material.dart';
import '../core/theme/migo_colors.dart';

class CategoryItem {
  const CategoryItem({required this.name, required this.icon});
  final String name;
  final IconData icon;
}

/// Grid of MIGO categories.
/// Shows first 6 on the home screen.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key, this.onCategoryTap, this.maxItems});

  final void Function(String name)? onCategoryTap;
  final int? maxItems;

  static const _allCategories = <CategoryItem>[
    CategoryItem(name: 'Food', icon: Icons.restaurant_outlined),
    CategoryItem(name: 'Beauty', icon: Icons.spa_outlined),
    CategoryItem(name: 'Auto', icon: Icons.directions_car_outlined),
    CategoryItem(name: 'Events', icon: Icons.celebration_outlined),
    CategoryItem(name: 'Photography', icon: Icons.camera_alt_outlined),
    CategoryItem(name: 'Fitness', icon: Icons.fitness_center_outlined),
    CategoryItem(name: 'Shopping', icon: Icons.shopping_bag_outlined),
    CategoryItem(name: 'Education', icon: Icons.school_outlined),
    CategoryItem(
      name: 'Home Services',
      icon: Icons.home_repair_service_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = maxItems != null
        ? _allCategories.take(maxItems!).toList()
        : _allCategories;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final c = items[i];
        return _CategoryTile(
          item: c,
          onTap: () => onCategoryTap?.call(c.name),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.item, this.onTap});

  final CategoryItem item;
  final VoidCallback? onTap;

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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MigoColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                size: 22,
                color: MigoColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: MigoColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}