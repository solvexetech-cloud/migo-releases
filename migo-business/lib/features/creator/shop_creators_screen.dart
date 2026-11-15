import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/migo_theme.dart';

class ShopCreatorsScreen extends StatefulWidget {
  final String businessId;
  const ShopCreatorsScreen({super.key, required this.businessId});

  @override
  State<ShopCreatorsScreen> createState() => _ShopCreatorsScreenState();
}

class _ShopCreatorsScreenState extends State<ShopCreatorsScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _recordCollab(Map<String, dynamic> creator) async {
    final feeController = TextEditingController();
    final offerIdController = TextEditingController();
    final endDateController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Record Collab with ${creator['displayName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: offerIdController,
              decoration: const InputDecoration(labelText: 'Offer ID (from My Offers)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Fee per Redemption (QAR)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: endDateController,
              decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (feeController.text.isEmpty || offerIdController.text.isEmpty) return;
              final fee = double.tryParse(feeController.text) ?? 0;
              final endDate = DateTime.tryParse(endDateController.text) ?? DateTime.now().add(const Duration(days: 30));

              await FirebaseFirestore.instance.collection('collabs').add({
                'shopId': widget.businessId,
                'creatorId': creator['userId'],
                'offerId': offerIdController.text.trim(),
                'feePerRedemption': fee,
                'currency': 'QAR',
                'endsAt': Timestamp.fromDate(endDate),
                'status': 'invited',
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Collab invitation sent to creator!')),
              );
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Creators'),
        backgroundColor: MigoColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search creators by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _search = val.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('creators')
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['displayName'] ?? '').toString().toLowerCase();
                  return name.contains(_search);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No creators found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final c = filtered[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: MigoColors.accent.withValues(alpha: 0.2),
                          child: Text((c['displayName'] ?? 'U')[0].toUpperCase()),
                        ),
                        title: Text(c['displayName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${c['category']} · ${c['followers']} followers'),
                        trailing: ElevatedButton(
                          onPressed: () => _recordCollab(c),
                          style: ElevatedButton.styleFrom(backgroundColor: MigoColors.primary),
                          child: const Text('Invite', style: TextStyle(color: Colors.white)),
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