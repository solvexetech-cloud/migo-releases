// migo-business/lib/features/demands/business_demands_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/localization/app_localizations.dart';
import 'my_bids_screen.dart';
import 'demand_bids_screen.dart';

class BusinessDemandsFeedScreen extends StatefulWidget {
  const BusinessDemandsFeedScreen({super.key});
  @override
  State<BusinessDemandsFeedScreen> createState() => _BusinessDemandsFeedScreenState();
}

class _BusinessDemandsFeedScreenState extends State<BusinessDemandsFeedScreen> {
  String? _businessCategory;

  bool _loadingCategory = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessCategory();
  }

  Future<void> _loadBusinessCategory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final bizSnapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .where('ownerUid', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (bizSnapshot.docs.isNotEmpty) {
        final category = bizSnapshot.docs.first.data()['category'] as String?;
        setState(() {
          _businessCategory = category;
          if (category != null && category.isNotEmpty) {
            
          }
          _loadingCategory = false;
        });
      } else {
        setState(() => _loadingCategory = false);
      }
    } catch (e) {
      setState(() => _loadingCategory = false);
    }
  }

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
            appBar: AppBar(
              title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(t.get('business_demands'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              backgroundColor: const Color(0xFF0F2B5B),
              foregroundColor: Colors.white,
            ),
            body: _loadingCategory 
              ? const Center(child: CircularProgressIndicator())
              : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, foregroundColor: const Color(0xFF0F2B5B),
                        side: const BorderSide(color: Color(0xFF0F2B5B), width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2,
                      ),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBidsScreen())),
                      icon: const Icon(Icons.receipt_long, size: 24),
                      label: Text(isAr ? 'ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶ ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¶Ãƒâ„¢Ã…Â  (My Bids)' : 'View My Bids', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
                
                // Category Display (Only show their own category)
                if (_businessCategory != null && _businessCategory!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.category, color: Color(0xFF0F2B5B)),
                        const SizedBox(width: 8),
                        Text(
                          '${isAr ? "Ãƒâ„¢Ã‚ÂÃƒËœÃ‚Â¦ÃƒËœÃ‚Â© Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚ÂªÃƒËœÃ‚Â¬ÃƒËœÃ‚Â±Ãƒâ„¢Ã†â€™" : "Your Shop Category"}: $_businessCategory',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F2B5B)),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('demand_groups')
                          .where('status', whereIn: ['threshold_reached', 'bidding'])
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(child: Text(isAr ? 'Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â§ ÃƒËœÃ‚ÂªÃƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â¯ ÃƒËœÃ‚Â·Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â§ÃƒËœÃ‚Âª Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â´ÃƒËœÃ‚Â·ÃƒËœÃ‚Â© ÃƒËœÃ‚Â­ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â¹' : 'No active demands currently', style: const TextStyle(fontSize: 16, color: Colors.grey)));
                        }

                        var demands = snapshot.data!.docs;

                        // ÃƒÂ°Ã…Â¸Ã¢â‚¬Â Ã¢â‚¬Â¢ STRICT CATEGORY FILTER
                        if (_businessCategory != null && _businessCategory!.isNotEmpty) {
                          demands = demands.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final cat = data['category']?.toString() ?? '';
                            return cat.toLowerCase() == _businessCategory!.toLowerCase();
                          }).toList();
                        }

                        if (demands.isEmpty) {
                          return Center(child: Text(isAr ? 'Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â§ ÃƒËœÃ‚ÂªÃƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â¯ ÃƒËœÃ‚Â·Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â§ÃƒËœÃ‚Âª Ãƒâ„¢Ã‚ÂÃƒâ„¢Ã…Â  Ãƒâ„¢Ã‚ÂÃƒËœÃ‚Â¦ÃƒËœÃ‚ÂªÃƒâ„¢Ã†â€™' : 'No demands in your category', style: const TextStyle(fontSize: 16, color: Colors.grey)));
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: demands.length,
                          itemBuilder: (context, index) {
                            final doc = demands[index];
                            final data = doc.data() as Map<String, dynamic>;
                            return _BusinessDemandCard(groupId: doc.id, data: data, isAr: isAr, t: t);
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

class _BusinessDemandCard extends StatelessWidget {
  final String groupId;
  final Map<String, dynamic> data;
  final bool isAr;
  final AppLocalizations t;

  const _BusinessDemandCard({required this.groupId, required this.data, required this.isAr, required this.t});

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? 'Unknown';
    final memberCount = (data['memberCount'] as num?)?.toInt() ?? 1;
    final totalQuantity = (data['totalQuantity'] as num?)?.toInt() ?? 0;
    final minPrice = (data['minTargetPrice'] as num?)?.toDouble() ?? 0.0;
    final maxPrice = (data['maxTargetPrice'] as num?)?.toDouble() ?? 0.0;
    final category = data['category']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => DemandBidsScreen(groupId: groupId, groupData: data)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(category, style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                  Text('$minPrice - $maxPrice QAR', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text('$memberCount ${t.get('people_want_this')}', style: TextStyle(color: Colors.blue.shade700, fontSize: 13, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${t.get('total_quantity')}: $totalQuantity', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F2B5B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DemandBidsScreen(groupId: groupId, groupData: data)));
                  },
                  child: Text(t.get('place_bid'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}