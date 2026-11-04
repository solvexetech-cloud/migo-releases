import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/demand_model.dart';
import '../../models/demand_claim_model.dart';
import 'bids_comparison_screen.dart';
import 'claim_ticket_screen.dart';

class MyDemandDetailsScreen extends StatelessWidget {
  final DemandModel demand;

  const MyDemandDetailsScreen({super.key, required this.demand});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';
        final title = demand.title[isAr ? 'ar' : 'en'] ?? demand.title['en'] ?? '';
        final desc = demand.description[isAr ? 'ar' : 'en'] ?? demand.description['en'] ?? '';

        final statusColor = demand.status == 'open'
            ? Colors.orange
            : (demand.status == 'threshold_reached' ? Colors.green : MigoColors.primary);

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: MigoColors.backgroundLight,
            appBar: AppBar(
              title: Text(isAr ? 'تفاصيل الطلب' : 'Demand Details',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: MigoColors.primaryDark,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [MigoColors.primary, MigoColors.primaryDark],
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
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (desc.isNotEmpty)
                          Text(
                            desc,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${demand.currency} ${demand.targetPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                demand.status == 'open'
                                    ? (isAr ? 'جمع الأعضاء' : 'Collecting')
                                    : (demand.status == 'threshold_reached'
                                        ? (isAr ? 'جاري المزايدة' : 'Bidding')
                                        : (isAr ? 'مغلق' : 'Closed')),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Group Progress
                  _SectionTitle(
                    title: isAr ? 'تقدم المجموعة' : 'Group Progress',
                    isAr: isAr,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: demand.requiredCount > 0
                                      ? (demand.currentCount / demand.requiredCount).clamp(0.0, 1.0)
                                      : 0.0,
                                  minHeight: 10,
                                  backgroundColor: Colors.grey[200],
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${demand.currentCount} / ${demand.requiredCount}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          demand.status == 'threshold_reached'
                              ? (isAr
                                  ? 'تم الوصول للعدد المطلوب! جاري انتظار العروض.'
                                  : 'Threshold reached! Waiting for bids.')
                              : (isAr
                                  ? 'نحتاج ${demand.requiredCount - demand.currentCount} أشخاص إضافيين.'
                                  : 'Need ${demand.requiredCount - demand.currentCount} more people.'),
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status Timeline
                  _SectionTitle(
                    title: isAr ? 'حالة الطلب' : 'Status Timeline',
                    isAr: isAr,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _TimelineItem(
                          label: isAr ? 'تم إنشاء الطلب' : 'Demand Created',
                          isDone: true,
                          isLast: false,
                        ),
                        _TimelineItem(
                          label: isAr ? 'انضممت للمجموعة' : 'Joined Group',
                          isDone: true,
                          isLast: false,
                        ),
                        _TimelineItem(
                          label: isAr ? 'جاري جمع الأعضاء' : 'Collecting Members',
                          isDone: demand.currentCount >= demand.requiredCount,
                          isLast: false,
                        ),
                        _TimelineItem(
                          label: isAr ? 'بدأت المزايدة' : 'Bidding Started',
                          isDone: demand.status == 'threshold_reached' || demand.status == 'locked',
                          isLast: false,
                        ),
                        _TimelineItem(
                          label: isAr ? 'تم تأكيد الطلب' : 'Order Confirmed',
                          isDone: false,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (demand.currentCount > 0 || demand.status == 'threshold_reached')
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: MigoColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BidsComparisonScreen(demand: demand),
                            ),
                          );
                        },
                        icon: const Icon(Icons.gavel),
                        label: Text(
                          isAr ? 'عرض العروض' : 'View Offers',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  if (demand.status == 'locked')
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: MigoColors.accent,
                          foregroundColor: MigoColors.primaryDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid == null) return;
                          
                          final snapshot = await FirebaseFirestore.instance
                              .collection('demand_claims')
                              .where('demandId', isEqualTo: demand.id)
                              .where('userId', isEqualTo: uid)
                              .limit(1)
                              .get();

                          if (snapshot.docs.isNotEmpty && context.mounted) {
                            final claim = DemandClaimModel.fromMap(
                              snapshot.docs.first.id,
                              snapshot.docs.first.data() as Map<String, dynamic>,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClaimTicketScreen(demand: demand, claim: claim),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.qr_code),
                        label: Text(
                          isAr ? 'عرض رمز الاسترداد' : 'View Redemption Ticket',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isAr;
  const _SectionTitle({required this.title, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: MigoColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: MigoColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isLast;
  const _TimelineItem({required this.label, required this.isDone, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDone ? MigoColors.success : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isDone ? MigoColors.success : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                color: isDone ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}