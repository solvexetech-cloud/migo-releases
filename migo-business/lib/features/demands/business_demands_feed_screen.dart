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
  String? _businessCategory;
  String _selectedFilter = 'All'; // ഡീഫോൾട്ട് 'All' എന്ന് വെക്കാം, പക്ഷേ UI-ൽ ബിസിനസ് കാറ്റഗറി ഹൈലൈറ്റ് ചെയ്യും
  bool _loadingCategory = true;
  bool _isPrivate = false;

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
          // ഡീഫോൾട്ട് ആയി ബിസിനസിന്റെ കാറ്റഗറി തിരഞ്ഞെടുക്കുക
          if (category != null && category.isNotEmpty) {
            _selectedFilter = category[0].toUpperCase() + category.substring(1).toLowerCase();
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
        final isAr = LocaleProvider.instance.locale == 'ar';

        // കാറ്റഗറി ലിസ്റ്റ് (All + ബിസിനസ് കാറ്റഗറി + മറ്റുള്ളവ)
        final List<String> displayCategories = [
          'All',
          if (_businessCategory != null && _businessCategory!.isNotEmpty)
            _businessCategory![0].toUpperCase() + _businessCategory!.substring(1).toLowerCase(),
          'Electronics', 'Food', 'Fashion', 'Home', 'Others'
        ].toSet().toList(); // ഡ്യൂപ്ലിക്കേറ്റ് ഒഴിവാക്കാൻ

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
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isPrivate = false),
                          child: Container(
                            decoration: BoxDecoration(
                              color: !_isPrivate ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: !_isPrivate ? Colors.blue : Colors.grey.shade300),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            child: Text(
                              isAr ? 'المجتمع' : 'Community',
                              style: TextStyle(
                                color: !_isPrivate ? Colors.blue : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isPrivate = true),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isPrivate ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _isPrivate ? Colors.blue : Colors.grey.shade300),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            child: Text(
                              isAr ? 'بيع خاص' : 'Private Bulk',
                              style: TextStyle(
                                color: _isPrivate ? Colors.blue : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: displayCategories.map((cat) {
                      final isSelected = _selectedFilter == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() => _selectedFilter = cat);
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
                Expanded(
                  child: _loadingCategory
                      ? const Center(child: CircularProgressIndicator())
                      : StreamBuilder<QuerySnapshot>(
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

                            // 1. Private / Community ഫിൽട്ടർ
                            demands = demands.where((d) => d.isPrivate == _isPrivate).toList();

                            // 2. Category ഫിൽട്ടർ (All അല്ലെങ്കിൽ സെലക്ട് ചെയ്ത കാറ്റഗറി)
                            if (_selectedFilter != 'All') {
                              demands = demands.where((d) => d.category.toLowerCase() == _selectedFilter.toLowerCase()).toList();
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
                                                  d.isPrivate ? (isAr ? 'بيع خاص' : 'Private') : (isAr ? 'المجتمع' : 'Community'),
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