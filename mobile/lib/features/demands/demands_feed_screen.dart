import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/demand_model.dart';
import '../../services/demand_service.dart';
import 'create_demand_screen.dart';
import 'bids_comparison_screen.dart';

class DemandsFeedScreen extends StatelessWidget {
  const DemandsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: MigoColors.backgroundLight,
            appBar: AppBar(
              title: Text(
                isAr ? 'طلبات المجتمع' : 'Community Demands',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: MigoColors.primaryDark,
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: DemandService().getDemandsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // If no demands, show a beautiful empty state with sample UI
                final bool isEmpty = !snapshot.hasData || snapshot.data!.docs.isEmpty;
                
                final demands = isEmpty 
                    ? [] 
                    : snapshot.data!.docs
                        .map((doc) => DemandModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                        .toList();

                return Stack(
                  children: [
                    // Main Content
                    ListView(
                      padding: const EdgeInsets.only(bottom: 100), // Space for FAB
                      children: [
                        // Hero Header
                        Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [MigoColors.primary, MigoColors.primaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: MigoColors.primary.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.gavel, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isAr ? 'اطلب أي منتج' : 'Request Any Product',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isAr 
                                  ? 'حدد المنتج والسعر الذي تريده، ودع المتاجر المحلية تتنافس لتقديم أفضل عرض لك.'
                                  : 'Set your desired product and price, then let local shops compete to give you the best offer.',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (isEmpty) ...[
                          // Beautiful Empty State Design
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                Icon(
                                  Icons.storefront_outlined,
                                  size: 80,
                                  color: MigoColors.primary.withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isAr ? 'لا توجد طلبات حالياً' : 'No demands yet',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: MigoColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isAr 
                                    ? 'كن أول من يطلب منتجاً وشاهد العروض تتوالى!'
                                    : 'Be the first to request a product and watch the offers roll in!',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: MigoColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                
                                // How it works steps
                                _buildStep(isAr, 1, isAr ? 'اطلب المنتج' : 'Request Product', isAr ? 'حدد اسم المنتج والسعر المطلوب.' : 'Enter product name and target price.'),
                                _buildStep(isAr, 2, isAr ? 'اجمع المهتمين' : 'Gather Interest', isAr ? 'شارك الطلب مع أصدقائك للوصول للعدد المطلوب.' : 'Share with friends to reach the required threshold.'),
                                _buildStep(isAr, 3, isAr ? 'اختر العرض' : 'Choose Offer', isAr ? 'قارن العروض من المتاجر واختر الأفضل.' : 'Compare shop bids and select the best one.'),
                              ],
                            ),
                          ),
                        ] else ...[
                          // List of Demands
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              isAr ? 'الطلبات النشطة' : 'Active Demands',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: MigoColors.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...demands.map((demand) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            child: _DemandCard(demand: demand, isAr: isAr),
                          )),
                        ],
                      ],
                    ),

                    // Floating Action Button (Glowing)
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [MigoColors.accent, MigoColors.accentDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: MigoColors.accent.withValues(alpha: 0.5),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                isAr ? 'طلب جديد' : 'New Demand',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
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

  // Helper widget for empty state steps
  Widget _buildStep(bool isAr, int number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MigoColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: MigoColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Existing Demand Card Widget (Keep as is)
class _DemandCard extends StatefulWidget {
  final DemandModel demand;
  final bool isAr;

  const _DemandCard({required this.demand, required this.isAr});

  @override
  State<_DemandCard> createState() => _DemandCardState();
}

class _DemandCardState extends State<_DemandCard> {
  bool _isJoining = false;

  Future<void> _joinDemand() async {
    setState(() => _isJoining = true);
    final success = await DemandService().joinDemand(widget.demand.id);
    
    if (!mounted) return; 
    setState(() => _isJoining = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isAr ? 'تم الانضمام بنجاح!' : 'Joined successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isAr ? 'تعذر الانضمام. ربما انضممت بالفعل أو اكتمل العدد.' : 'Could not join. Maybe already joined or threshold reached.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final demand = widget.demand;
    final isAr = widget.isAr;
    
    final title = demand.title[isAr ? 'ar' : 'en'] ?? demand.title['en'] ?? '';
    final description = demand.description[isAr ? 'ar' : 'en'] ?? demand.description['en'] ?? '';

    final progress = demand.requiredCount > 0 
        ? (demand.currentCount / demand.requiredCount).clamp(0.0, 1.0) 
        : 0.0;

    final isThresholdReached = demand.status == 'threshold_reached';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: MigoColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${demand.currency} ${demand.targetPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: MigoColors.primary),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      color: isThresholdReached ? Colors.green : MigoColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${demand.currentCount} / ${demand.requiredCount}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isThresholdReached ? Colors.green : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isThresholdReached
                  ? (isAr ? 'تم الوصول للعدد المطلوب! جاري انتظار العروض.' : 'Threshold reached! Waiting for bids.')
                  : (isAr ? 'نحتاج ${demand.requiredCount - demand.currentCount} أشخاص إضافيين' : 'Need ${demand.requiredCount - demand.currentCount} more people'),
              style: TextStyle(
                fontSize: 11,
                color: isThresholdReached ? Colors.green : Colors.grey,
                fontWeight: isThresholdReached ? FontWeight.bold : FontWeight.normal,
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: isThresholdReached
                  ? OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BidsComparisonScreen(demand: widget.demand),
                          ),
                        );
                      },
                      icon: const Icon(Icons.gavel),
                      label: Text(isAr ? 'عرض العروض' : 'View Bids'),
                    )
                  : FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: MigoColors.primary,
                      ),
                      onPressed: _isJoining ? null : _joinDemand,
                      icon: _isJoining 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.group_add),
                      label: Text(
                        _isJoining 
                            ? (isAr ? 'جاري الانضمام...' : 'Joining...') 
                            : (isAr ? 'انضم للطلب' : 'Join Demand'),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}