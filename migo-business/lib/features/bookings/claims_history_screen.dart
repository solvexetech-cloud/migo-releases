import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/migo_theme.dart';

class ClaimsHistoryScreen extends StatefulWidget {
  final String businessId;
  const ClaimsHistoryScreen({super.key, required this.businessId});

  @override
  State<ClaimsHistoryScreen> createState() => _ClaimsHistoryScreenState();
}

class _ClaimsHistoryScreenState extends State<ClaimsHistoryScreen> {
  String _filter = 'all'; // all, active, redeemed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Claims'),
        backgroundColor: MigoColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Active', 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('Redeemed', 'redeemed'),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('claims')
                  .where('businessId', isEqualTo: widget.businessId)
                  .orderBy('claimedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                
                // Client-side filter
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] as String? ?? '';
                  if (_filter == 'all') return true;
                  return status == _filter;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text('No claims yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildClaimCard(data, doc.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filter = value);
      },
      selectedColor: MigoColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? MigoColors.primary : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildClaimCard(Map<String, dynamic> data, String docId) {
    final offerTitle = data['offerTitle'] as String? ?? 'Unknown Offer';
    final status = data['status'] as String? ?? 'unknown';
    final claimedAt = (data['claimedAt'] as Timestamp?)?.toDate();
    final userUid = data['userUid'] as String? ?? '';
    final price = (data['offerPrice'] as num?)?.toDouble() ?? 0;
    final currency = data['currency'] as String? ?? 'QAR';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'active':
        statusColor = Colors.blue;
        statusLabel = 'ACTIVE';
        break;
      case 'redeemed':
        statusColor = MigoColors.success;
        statusLabel = 'REDEEMED';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  offerTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'UID: ${userUid.substring(0, 8)}...',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              Text(
                '$currency ${price.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: MigoColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                claimedAt != null 
                    ? '${claimedAt.day}/${claimedAt.month}/${claimedAt.year} ${claimedAt.hour}:${claimedAt.minute.toString().padLeft(2, '0')}'
                    : 'Unknown date',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}