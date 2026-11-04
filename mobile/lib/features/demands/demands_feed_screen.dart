import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/demand_model.dart';
import '../../services/demand_service.dart';
import 'create_demand_screen.dart';
import 'bids_comparison_screen.dart';
import 'my_demands_screen.dart';

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
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              title: Text(
                isAr ? 'طلبات المجتمع' : 'Community Demands',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: MigoColors.primaryDark,
              actions: [
                // 🆕 "My Demands" എന്ന ബട്ടൺ
                Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyDemandsScreen()),
                    ),
                    icon: const Icon(Icons.receipt_long, size: 16),
                    label: Text(
                      isAr ? 'طلباتي' : 'My Demands',
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
              stream: DemandService().getDemandsStream(
                isPrivate: false,
                category: _selectedCategory == 'All' ? null : _selectedCategory,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final bool isEmpty = !snapshot.hasData || snapshot.data!.docs.isEmpty;
                
                final demands = isEmpty 
                    ? [] 
                    : snapshot.data!.docs
                        .map((doc) => DemandModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                        .toList();

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
                                        isAr ? 'اطلب أي منتج' : 'Request Any Product',
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
                                    ? 'حدد المنتج والسعر الذي تريده، ودع المتاجر المحلية تتنافس لتقديم أفضل عرض لك.'
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
                        if (isEmpty)
                          _buildEmptyState(isAr)
                        else ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              isAr ? 'الطلبات النشطة' : 'Active Demands',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...demands.map((demand) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: _NewDemandCard(demand: demand, isAr: isAr),
                          )),
                        ],
                      ],
                    ),

                    // Floating Action Button
                    Positioned(
                      bottom: 24,
                      right: isAr ? null : 24,
                      left: isAr ? 24 : null,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateDemandScreen()),
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
                                isAr ? 'طلب جديد' : 'New Demand',
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
            isAr ? 'لا توجد طلبات حالياً' : 'No demands yet',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MigoColors.textPrimaryLight),
          ),
          const SizedBox(height: 8),
          Text(
            isAr ? 'كن أول من يطلب منتجاً وشاهد العروض تتوالى!' : 'Be the first to request a product!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: MigoColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }
}

// 🆕 പുതിയ മോഡേൺ ഡിമാൻഡ് കാർഡ് (Border & Colorful UI)
class _NewDemandCard extends StatefulWidget {
  final DemandModel demand;
  final bool isAr;

  const _NewDemandCard({required this.demand, required this.isAr});

  @override
  State<_NewDemandCard> createState() => _NewDemandCardState();
}

class _NewDemandCardState extends State<_NewDemandCard> {
  bool _isJoining = false;

  Future<void> _joinDemand() async {
    setState(() => _isJoining = true);
    final success = await DemandService().joinDemand(widget.demand.id);
    
    if (!mounted) return; 
    setState(() => _isJoining = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isAr ? 'تم الانضمام بنجاح!' : 'Joined successfully!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isAr ? 'تعذر الانضمام.' : 'Could not join.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final demand = widget.demand;
    final isAr = widget.isAr;
    
    final title = demand.title[isAr ? 'ar' : 'en'] ?? demand.title['en'] ?? '';
    final description = demand.description[isAr ? 'ar' : 'en'] ?? demand.description['en'] ?? '';

    final progress = demand.minRequiredCount > 0 
        ? (demand.currentCount / demand.minRequiredCount).clamp(0.0, 1.0) 
        : 0.0;

    final isThresholdReached = demand.currentCount >= demand.minRequiredCount;

    // തീയതി ഫോർമാറ്റ്
    final createdDate = demand.createdAt;
    final formattedDate = '${createdDate.day}/${createdDate.month}/${createdDate.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // 🆕 ബോർഡർ ചേർത്തു
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
            // Category Tag & Price
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
                    demand.category,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                  ),
                ),
                Text(
                  '${demand.currency} ${demand.targetPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: MigoColors.primaryDark),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Title & Description
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Created Date
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${isAr ? 'تاريخ الإنشاء' : 'Created'}: $formattedDate',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),

            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Progress & Avatars
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      color: isThresholdReached ? Colors.green : MigoColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${demand.currentCount}/${demand.minRequiredCount}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isThresholdReached ? Colors.green : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              isThresholdReached
                  ? (isAr ? 'تم الوصول للعدد المطلوب!' : 'Threshold reached!')
                  : (isAr ? 'نحتاج ${demand.minRequiredCount - demand.currentCount} أشخاص إضافيين' : 'Need ${demand.minRequiredCount - demand.currentCount} more people'),
              style: TextStyle(
                fontSize: 12,
                color: isThresholdReached ? Colors.green : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: isThresholdReached
                  ? ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => BidsComparisonScreen(demand: widget.demand)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MigoColors.primaryDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.gavel, color: Colors.white, size: 18),
                      label: Text(isAr ? 'عرض العروض' : 'View Offers', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MigoColors.primary.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isJoining ? null : _joinDemand,
                      icon: _isJoining 
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: MigoColors.primary, strokeWidth: 2))
                          : const Icon(Icons.group_add, color: MigoColors.primary, size: 18),
                      label: Text(
                        _isJoining 
                            ? (isAr ? 'جاري الانضمام...' : 'Joining...') 
                            : (isAr ? 'انضم للطلب' : 'Join Demand'),
                        style: const TextStyle(color: MigoColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}