import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/localization/locale_provider.dart';
import '../../models/demand_model.dart';
import '../../services/demand_service.dart';
import 'my_bids_screen.dart';
import 'demand_bids_screen.dart';

class BusinessDemandsFeedScreen extends StatefulWidget {
  const BusinessDemandsFeedScreen({super.key});

  @override
  State<BusinessDemandsFeedScreen> createState() => _BusinessDemandsFeedScreenState();
}

class _BusinessDemandsFeedScreenState extends State<BusinessDemandsFeedScreen> {
  String _filter = 'All';
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
            appBar: AppBar(
              title: Text(isAr ? 'الطلبات' : 'Demands', style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFF0F2B5B),
              foregroundColor: Colors.white,
            ),
            body: Column(
              children: [
                // 🆕 My Bids ബട്ടൺ ഇവിടെ ചേർത്തു
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F2B5B),
                        side: const BorderSide(color: Color(0xFF0F2B5B), width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyBidsScreen()),
                        );
                      },
                      icon: const Icon(Icons.receipt_long, size: 24),
                      label: Text(
                        isAr ? 'عرض عروضي (My Bids)' : 'View My Bids',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ),

                // Category Tabs
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          child: Text(
                            isAr ? 'المجتمع' : 'Community',
                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          child: Text(
                            isAr ? 'بيع خاص' : 'Private Bulk',
                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _filter == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() => _filter = cat);
                          },
                          selectedColor: const Color(0xFF0F2B5B),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Demands List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: DemandService().getDemandsStream(status: 'threshold_reached'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            isAr ? 'لا توجد طلبات نشطة حالياً' : 'No active demands currently',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }

                      var demands = snapshot.data!.docs
                          .map((doc) => DemandModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                          .toList();

                      if (_filter != 'All') {
                        demands = demands.where((d) => d.category.toLowerCase() == _filter.toLowerCase()).toList();
                      }

                      if (demands.isEmpty) {
                        return Center(
                          child: Text(
                            isAr ? 'لا توجد طلبات في هذا القسم' : 'No demands in this category',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: demands.length,
                        itemBuilder: (context, index) {
                          final d = demands[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => DemandBidsScreen(demand: d)),
                                );
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
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isAr ? 'المجتمع' : 'Community',
                                            style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Text(
                                          'Target: ${d.currency} ${d.targetPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      d.title['en'] ?? '',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    if (d.description['en'] != null && d.description['en']!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        d.description['en']!,
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${d.currentCount} ${isAr ? 'منضم' : 'Joined'}',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 45,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0F2B5B),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => DemandBidsScreen(demand: d)),
                                          );
                                        },
                                        child: Text(
                                          isAr ? 'تقديم عرض' : 'Submit Offer',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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