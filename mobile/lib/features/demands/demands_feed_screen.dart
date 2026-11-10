// mobile/lib/features/demands/demands_feed_screen.dart
// UPDATED FILE - Confusion-free Community Demands View
// Created: Nov 09, 2026

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/migo_colors.dart';
import 'new_demand_screen.dart'; // Ã°Å¸â€ â€¢ Ã Â´ÂªÃ ÂµÂÃ Â´Â¤Ã Â´Â¿Ã Â´Â¯ Ã Â´Â¸Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´Â°Ã Âµâ‚¬Ã ÂµÂ»
import 'my_demands_screen.dart';
import 'bids_comparison_screen.dart';

class DemandsFeedScreen extends StatefulWidget {
  const DemandsFeedScreen({super.key});

  @override
  State<DemandsFeedScreen> createState() => _DemandsFeedScreenState();
}

class _DemandsFeedScreenState extends State<DemandsFeedScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Electronics', 'Food', 'Fashion', 'Home', 'Others'];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final t = AppLocalizations.of(context)!;
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              title: Text(
                isAr ? 'Ã˜Â·Ã™â€žÃ˜Â¨Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â¬Ã˜ÂªÃ™â€¦Ã˜Â¹' : 'Community Demands',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: MigoColors.primaryDark,
              actions: [
                // My Demands Button
                Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyDemandsScreen()),
                    ),
                    icon: const Icon(Icons.receipt_long, size: 16),
                    label: Text(
                      t.get('my_demands'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MigoColors.primary.withValues(alpha: 0.1),
                      foregroundColor: MigoColors.primaryDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
            body: StreamBuilder<QuerySnapshot>(
              // Ã°Å¸â€ â€¢ Fetch from 'demand_groups' (threshold reached only)
              stream: FirebaseFirestore.instance
                  .collection('demand_groups')
                  .where('status', whereIn: ['threshold_reached', 'bidding'])
                  
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var groups = snapshot.data?.docs ?? [];

                // Apply category filter
                if (_selectedCategory != 'All') {
                  groups = groups.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['category'].toString().toLowerCase() == _selectedCategory.toLowerCase();
                  }).toList();
                }

                return Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.only(bottom: 100),
                      children: [
                        // Modern Header
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        isAr ? 'Ã˜Â§Ã˜Â·Ã™â€žÃ˜Â¨ Ã˜Â£Ã™Å  Ã™â€¦Ã™â€ Ã˜ÂªÃ˜Â¬' : 'Request Any Product',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isAr 
                                    ? 'Ã˜Â­Ã˜Â¯Ã˜Â¯ Ã˜Â§Ã™â€žÃ™â€¦Ã™â€ Ã˜ÂªÃ˜Â¬ Ã™Ë†Ã˜Â§Ã™â€žÃ˜Â³Ã˜Â¹Ã˜Â± Ã˜Â§Ã™â€žÃ˜Â°Ã™Å  Ã˜ÂªÃ˜Â±Ã™Å Ã˜Â¯Ã™â€¡Ã˜Å’ Ã™Ë†Ã˜Â¯Ã˜Â¹ Ã˜Â§Ã™â€žÃ™â€¦Ã˜ÂªÃ˜Â§Ã˜Â¬Ã˜Â± Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â­Ã™â€žÃ™Å Ã˜Â© Ã˜ÂªÃ˜ÂªÃ™â€ Ã˜Â§Ã™ÂÃ˜Â³ Ã™â€žÃ˜ÂªÃ™â€šÃ˜Â¯Ã™Å Ã™â€¦ Ã˜Â£Ã™ÂÃ˜Â¶Ã™â€ž Ã˜Â¹Ã˜Â±Ã˜Â¶ Ã™â€žÃ™Æ’.'
                                    : 'Set your desired product and price, then let local shops compete to give you the best offer.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Category Filter
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              final isSelected = _selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  onSelected: (val) => setState(() => _selectedCategory = cat),
                                  selectedColor: MigoColors.primaryDark,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                                  ),
                                  elevation: 0,
                                  pressElevation: 0,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Demands List
                        if (groups.isEmpty)
                          _buildEmptyState(isAr)
                        else ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              isAr ? 'Ã˜Â§Ã™â€žÃ˜Â·Ã™â€žÃ˜Â¨Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€žÃ™â€ Ã˜Â´Ã˜Â·Ã˜Â©' : 'Active Demands',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...groups.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: _NewDemandCard(
                                groupId: doc.id,
                                data: data,
                                isAr: isAr,
                                t: t,
                              ),
                            );
                          }),
                        ],
                      ],
                    ),

                    // Floating Action Button (Navigate to NewDemandScreen)
                    Positioned(
                      bottom: 24,
                      right: isAr ? null : 24,
                      left: isAr ? 24 : null,
                      child: GestureDetector(
                        onTap: () {
                          // Ã°Å¸â€ â€¢ Ã Â´ÂªÃ ÂµÂÃ Â´Â¤Ã Â´Â¿Ã Â´Â¯ Ã Â´Â¸Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´Â°Ã Âµâ‚¬Ã Â´Â¨Ã Â´Â¿Ã Â´Â²Ã Âµâ€¡Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂ Ã Â´ÂªÃ Âµâ€¹Ã Â´â€¢Ã ÂµÂÃ Â´Â¨Ã ÂµÂÃ Â´Â¨Ã ÂµÂ
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NewDemandScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                t.get('new_demand'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildEmptyState(bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.storefront_outlined, size: 80, color: MigoColors.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            isAr ? 'Ã™â€žÃ˜Â§ Ã˜ÂªÃ™Ë†Ã˜Â¬Ã˜Â¯ Ã˜Â·Ã™â€žÃ˜Â¨Ã˜Â§Ã˜Âª Ã˜Â­Ã˜Â§Ã™â€žÃ™Å Ã˜Â§Ã™â€¹' : 'No demands yet',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MigoColors.textPrimaryLight),
          ),
          const SizedBox(height: 8),
          Text(
            isAr ? 'Ã™Æ’Ã™â€  Ã˜Â£Ã™Ë†Ã™â€ž Ã™â€¦Ã™â€  Ã™Å Ã˜Â·Ã™â€žÃ˜Â¨ Ã™â€¦Ã™â€ Ã˜ÂªÃ˜Â¬Ã˜Â§Ã™â€¹ Ã™Ë†Ã˜Â´Ã˜Â§Ã™â€¡Ã˜Â¯ Ã˜Â§Ã™â€žÃ˜Â¹Ã˜Â±Ã™Ë†Ã˜Â¶ Ã˜ÂªÃ˜ÂªÃ™Ë†Ã˜Â§Ã™â€žÃ™â€°!' : 'Be the first to request a product!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: MigoColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }
}

// Ã°Å¸â€ â€¢ Ã Â´ÂªÃ ÂµÂÃ Â´Â¤Ã Â´Â¿Ã Â´Â¯ Ã Â´Â®Ã Âµâ€¹Ã Â´Â¡Ã Âµâ€¡Ã ÂµÂº Ã Â´Â¡Ã Â´Â¿Ã Â´Â®Ã Â´Â¾Ã ÂµÂ»Ã Â´Â¡Ã ÂµÂ Ã Â´â€¢Ã Â´Â¾Ã ÂµÂ¼Ã Â´Â¡Ã ÂµÂ (Without Join / Progress)
class _NewDemandCard extends StatelessWidget {
  final String groupId;
  final Map<String, dynamic> data;
  final bool isAr;
  final AppLocalizations t;

  const _NewDemandCard({
    required this.groupId,
    required this.data,
    required this.isAr,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? '';
    final memberCount = data['memberCount'] ?? 0;
    final totalQuantity = data['totalQuantity'] ?? 0;
    final minPrice = data['minTargetPrice'] ?? 0.0;
    final maxPrice = data['maxTargetPrice'] ?? 0.0;
    final category = data['category'] ?? '';

    final createdDate = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final formattedDate = '${createdDate.day}/${createdDate.month}/${createdDate.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Price Range
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                  ),
                ),
                Text(
                  '$minPrice - $maxPrice QAR',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: MigoColors.primaryDark),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Title
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Date
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${isAr ? 'Ã˜ÂªÃ˜Â§Ã˜Â±Ã™Å Ã˜Â® Ã˜Â§Ã™â€žÃ˜Â¥Ã™â€ Ã˜Â´Ã˜Â§Ã˜Â¡' : 'Created'}: $formattedDate',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Member Count (No Progress Bar)
            Row(
              children: [
                Icon(Icons.people, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Text(
                  '$memberCount ${t.get('people_want_this')}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${t.get('total_quantity')}: $totalQuantity',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to Bids Comparison
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BidsComparisonScreen(groupId: groupId, groupData: data),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MigoColors.primaryDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.gavel, color: Colors.white, size: 18),
                label: Text(
                  isAr ? 'Ã˜Â¹Ã˜Â±Ã˜Â¶ Ã˜Â§Ã™â€žÃ˜Â¹Ã˜Â±Ã™Ë†Ã˜Â¶' : 'View Offers', 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}