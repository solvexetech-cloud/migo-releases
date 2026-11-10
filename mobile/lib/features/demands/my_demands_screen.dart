// mobile/lib/features/demands/my_demands_screen.dart
// UPDATED - Added Active and History Tabs
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/migo_colors.dart';
import 'my_demand_details_screen.dart';

class MyDemandsScreen extends StatefulWidget {
  const MyDemandsScreen({super.key});

  @override
  State<MyDemandsScreen> createState() => _MyDemandsScreenState();
}

class _MyDemandsScreenState extends State<MyDemandsScreen> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final t = AppLocalizations.of(context)!;
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
              title: Text(t.get('my_demands'), style: const TextStyle(fontWeight: FontWeight.w800)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: MigoColors.primaryDark,
            ),
            body: Column(
              children: [
                // 🆕 Tabs for Active & History
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _showHistory = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !_showHistory ? MigoColors.primaryDark : Colors.grey.shade300,
                            foregroundColor: !_showHistory ? Colors.white : Colors.black87,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: Text(isAr ? 'نشط' : 'Active'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _showHistory = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _showHistory ? MigoColors.primaryDark : Colors.grey.shade300,
                            foregroundColor: _showHistory ? Colors.white : Colors.black87,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: Text(isAr ? 'السجل' : 'History'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('demand_groups')
                        .where('members', arrayContains: uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                         return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final allDocs = snapshot.data?.docs ?? [];
                      
                      // 🆕 Filter based on tab
                      final docs = allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] ?? 'collecting';
                        return _showHistory ? status == 'fulfilled' : status != 'fulfilled';
                      }).toList();

                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 80, color: MigoColors.primary.withValues(alpha: 0.2)),
                              const SizedBox(height: 16),
                              Text(
                                _showHistory 
                                  ? (isAr ? 'لا يوجد سجل' : 'No history yet') 
                                  : (isAr ? 'لا توجد طلبات نشطة' : 'No active demands'), 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final doc = docs[i];
                          final data = doc.data() as Map<String, dynamic>;
                          return _MyDemandCard(groupId: doc.id, data: data, isAr: isAr, t: t);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MyDemandCard extends StatelessWidget {
  final String groupId;
  final Map<String, dynamic> data;
  final bool isAr;
  final AppLocalizations t;

  const _MyDemandCard({required this.groupId, required this.data, required this.isAr, required this.t});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? '';
    final status = data['status'] ?? 'collecting';
    final memberCount = data['memberCount'] ?? 1;
    final totalQuantity = data['totalQuantity'] ?? 0;
    final threshold = data['threshold'] ?? 3;
    final isBulk = threshold == 1; 

    String statusText;
    Color statusColor;

    if (status == 'collecting') {
      statusText = t.get('waiting_for_people');
      statusColor = Colors.orange;
    } else if (status == 'threshold_reached') {
      statusText = isBulk ? (isAr ? 'طلب خاص' : 'Personal Order') : (isAr ? 'بدأت المجموعة' : 'Group started');
      statusColor = isBulk ? Colors.purple : Colors.green;
    } else if (status == 'bidding') {
      statusText = t.get('receiving_offers');
      statusColor = Colors.blue;
    } else if (status == 'fulfilled') {
      statusText = isAr ? 'مكتمل' : 'Completed';
      statusColor = Colors.green.shade700;
    } else {
      statusText = status;
      statusColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MyDemandDetailsScreen(demandId: groupId, data: data),
        ));
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: isBulk ? Colors.purple : Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text(
                    isBulk ? (isAr ? 'طلبك الخاص' : 'Your Personal Order') : (memberCount > 1 ? '$memberCount ${t.get('people_want_this')}' : (isAr ? 'طلبك' : 'Your Demand')), 
                    style: TextStyle(fontSize: 12, color: isBulk ? Colors.purple : Colors.blue.shade700, fontWeight: FontWeight.bold)
                  ),
                  const Spacer(),
                  Text('${t.get('total_quantity')}: $totalQuantity', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              // 🆕 Fetch and show Redeemed Date from claims collection
              if (status == 'fulfilled')
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('demand_claims')
                      .where('groupId', isEqualTo: groupId)
                      .where('status', isEqualTo: 'redeemed')
                      .limit(1)
                      .get(),
                  builder: (context, claimSnap) {
                    if (claimSnap.hasData && claimSnap.data!.docs.isNotEmpty) {
                      final claimData = claimSnap.data!.docs.first.data() as Map<String, dynamic>;
                      final redeemedAt = (claimData['redeemedAt'] as Timestamp?)?.toDate();
                      if (redeemedAt != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                '${isAr ? 'تم الاسترداد' : 'Redeemed'}: ${redeemedAt.day}/${redeemedAt.month}/${redeemedAt.year} - ${redeemedAt.hour}:${redeemedAt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}