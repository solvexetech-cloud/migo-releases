import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/demand_model.dart';
import '../../services/demand_service.dart'; // ബിസിനസ് ആപ്പിലെ സർവീസ്
import 'demand_bids_screen.dart'; // നിങ്ങളുടെ ഓഫർ ഇടുന്ന സ്ക്രീൻ

class BusinessDemandsFeedScreen extends StatefulWidget {
  const BusinessDemandsFeedScreen({super.key});

  @override
  State<BusinessDemandsFeedScreen> createState() => _BusinessDemandsFeedScreenState();
}

class _BusinessDemandsFeedScreenState extends State<BusinessDemandsFeedScreen> {
  String _selectedTab = 'Community'; // Community അല്ലെങ്കിൽ Private
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Electronics', 'Food', 'Fashion', 'Home', 'Others'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Demands', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Tabs (Community / Private)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 'Community'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTab == 'Community' ? Colors.blue.shade50 : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _selectedTab == 'Community' ? Colors.blue : Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text('Community', style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _selectedTab == 'Community' ? Colors.blue : Colors.grey,
                        )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 'Private'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTab == 'Private' ? Colors.orange.shade50 : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _selectedTab == 'Private' ? Colors.orange : Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text('Private Bulk', style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _selectedTab == 'Private' ? Colors.orange : Colors.grey,
                        )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

                    // Category Filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    selectedColor: Colors.blue.shade800,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87, 
                      fontSize: 13, // 🆕 ഫോണ്ട് സൈസ് ചെറുതാക്കി
                    ),
                  ),
                );
              },
            ),
          ),

          // Demands List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: DemandService().getDemandsStream(
                isPrivate: _selectedTab == 'Private',
                category: _selectedCategory == 'All' ? null : _selectedCategory,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No demands available right now.'));
                }

                final demands = snapshot.data!.docs
                    .map((doc) => DemandModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: demands.length,
                  itemBuilder: (context, index) {
                    final demand = demands[index];
                    
                    // പ്രൈവറ്റ് ആണെങ്കിൽ മിനിമം പേർ ഉണ്ടോ എന്ന് ചെക്ക് ചെയ്യാം (ഓപ്ഷണൽ)
                    if (_selectedTab == 'Private' && demand.currentCount < 1) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                    color: _selectedTab == 'Private' ? Colors.orange.shade100 : Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _selectedTab == 'Private' ? 'Bulk Order' : 'Community',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedTab == 'Private' ? Colors.orange.shade900 : Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Target: ${demand.targetPrice} QAR',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              demand.title['en'] ?? '',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            if (demand.description['en'] != null && demand.description['en']!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(demand.description['en']!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                            const SizedBox(height: 12),
                            
                            // Details row
                            Row(
                              children: [
                                const Icon(Icons.people, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('${demand.currentCount} Joined', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                const Spacer(),
                                if (demand.isPrivate)
                                  Text('Qty: ${demand.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),

                            // Delivery Date (Private Only)
                            if (demand.isPrivate && demand.deliveryDate != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 14, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Needed by: ${demand.deliveryDate!.day}/${demand.deliveryDate!.month}/${demand.deliveryDate!.year}',
                                    style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                            
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                  onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DemandBidsScreen(demand: demand), 
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black87,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Submit Offer', style: TextStyle(color: Colors.white)),
                              ),
                            )
                          ],
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
    );
  }
}