import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/demand_model.dart';
import 'my_demand_details_screen.dart';

class MyDemandsScreen extends StatelessWidget {
  const MyDemandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';
        final uid = FirebaseAuth.instance.currentUser?.uid;

        if (uid == null) {
          return Scaffold(body: Center(child: Text(isAr ? 'يرجى تسجيل الدخول' : 'Please sign in')));
        }

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: MigoColors.backgroundLight,
            appBar: AppBar(
              title: Text(isAr ? 'طلباتي' : 'My Demands', style: const TextStyle(fontWeight: FontWeight.w800)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: MigoColors.primaryDark,
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('demand_joins')
                  .where('userId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, joinSnap) {
                if (joinSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final joinedDocs = joinSnap.data?.docs ?? [];
                if (joinedDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 80, color: MigoColors.primary.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text(
                          isAr ? 'لم تنضم إلى أي طلبات بعد' : 'No demands joined yet',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final demandIds = joinedDocs.map((doc) => doc['demandId'] as String).toList();

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('demands')
                      .where(FieldPath.documentId, whereIn: demandIds)
                      .snapshots(),
                  builder: (context, demandSnap) {
                    if (demandSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final demands = demandSnap.data?.docs ?? [];
                    if (demands.isEmpty) {
                      return Center(child: Text(isAr ? 'لا توجد بيانات' : 'No data found'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: demands.length,
                      itemBuilder: (context, i) {
                        final doc = demands[i];
                        final demand = DemandModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                        return _MyDemandCard(demand: demand, isAr: isAr);
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _MyDemandCard extends StatelessWidget {
  final DemandModel demand;
  final bool isAr;

  const _MyDemandCard({required this.demand, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final title = demand.title[isAr ? 'ar' : 'en'] ?? demand.title['en'] ?? '';
    final statusColor = demand.status == 'open' 
        ? Colors.orange 
        : (demand.status == 'threshold_reached' ? Colors.green : MigoColors.primary);

    // 🆕 തീയതി ഫോർമാറ്റ് ചെയ്യാൻ
    final createdDate = demand.createdAt;
    final formattedDate = '${createdDate.day}/${createdDate.month}/${createdDate.year}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MyDemandDetailsScreen(demand: demand),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🆕 Header: Title, Status, Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      demand.status == 'open' 
                          ? (isAr ? 'جمع الأعضاء' : 'Collecting')
                          : (demand.status == 'threshold_reached' ? (isAr ? 'جاري المزايدة' : 'Bidding') : (isAr ? 'مغلق' : 'Closed')),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // 🆕 Created Date
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
              const SizedBox(height: 8),
              Text(
                '${demand.currency} ${demand.targetPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: MigoColors.primary),
              ),
              const SizedBox(height: 12),
              
              // Progress Bar
              if (!demand.isPrivate)
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

              const SizedBox(height: 12),
              // 🆕 Group Buy Avatars (Sample UI)
              Row(
                children: [
                  // Sample avatars to show people joined
                  for (int i = 0; i < (demand.currentCount > 3 ? 3 : demand.currentCount); i++)
                    Align(
                      widthFactor: 0.7,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(Icons.person, size: 16, color: Colors.blue.shade700),
                      ),
                    ),
                  if (demand.currentCount > 3)
                    Align(
                      widthFactor: 0.7,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.grey.shade200,
                        child: Text(
                          '+${demand.currentCount - 3}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ),
                    ),
                  if (demand.currentCount < demand.requiredCount)
                    Text(
                      isAr ? (demand.isPrivate ? '  عرض العروض' : '  انضم للمجموعة!') : (demand.isPrivate ? '  View Bids' : '  Join the group!'),
                      style: TextStyle(fontSize: 11, color: MigoColors.primary, fontWeight: FontWeight.bold),
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}