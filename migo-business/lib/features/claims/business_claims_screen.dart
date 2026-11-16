import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_theme.dart';

class BusinessClaimsScreen extends StatefulWidget {
  final String businessId;
  const BusinessClaimsScreen({super.key, required this.businessId});

  @override
  State<BusinessClaimsScreen> createState() => _BusinessClaimsScreenState();
}

class _BusinessClaimsScreenState extends State<BusinessClaimsScreen> {
  bool _showHistory = false;
  String _searchQuery = '';
  DateTime? _selectedDate;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🆕 Date Picker
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // 🆕 Clear Date Filter
  void _clearDate() {
    setState(() => _selectedDate = null);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Scaffold(
          appBar: AppBar(
            title: Text(isAr ? 'مطالبات العملاء' : 'Customer Claims'),
            backgroundColor: MigoColors.primary,
            foregroundColor: Colors.white,
            actions: [
              TextButton(
                onPressed: () => setState(() => _showHistory = !_showHistory),
                child: Text(
                  _showHistory ? (isAr ? 'السجل' : 'History') : (isAr ? 'نشط' : 'Active'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // 🆕 Search Bar & Calendar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: isAr ? 'ابحث بالاسم أو PIN...' : 'Search by title, PIN...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 🆕 Calendar Button
                    Container(
                      decoration: BoxDecoration(
                        color: _selectedDate != null ? MigoColors.primary : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.calendar_month, color: _selectedDate != null ? Colors.white : Colors.black87),
                        onPressed: _pickDate,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 🆕 Selected Date Chip
              if (_selectedDate != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Chip(
                        label: Text('${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                        onDeleted: _clearDate,
                        backgroundColor: MigoColors.primary.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(color: MigoColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('claims')
                      .where('businessId', isEqualTo: widget.businessId)
                      .where('status', isEqualTo: _showHistory ? 'redeemed' : 'active')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var docs = snapshot.data?.docs ?? [];
                    
                    // 🆕 Filter by search query & date
                    if (_searchQuery.isNotEmpty || _selectedDate != null) {
                      docs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = (data['offerTitle'] ?? '').toString().toLowerCase();
                        final pin = (data['pickupCode'] ?? '').toString().toLowerCase();
                        
                        bool matchesSearch = true;
                        if (_searchQuery.isNotEmpty) {
                          matchesSearch = title.contains(_searchQuery) || pin.contains(_searchQuery);
                        }

                        bool matchesDate = true;
                        if (_selectedDate != null) {
                          final redeemedAt = (data['redeemedAt'] as Timestamp?)?.toDate();
                          final claimedAt = (data['claimedAt'] as Timestamp?)?.toDate();
                          final targetDate = redeemedAt ?? claimedAt;
                          if (targetDate != null) {
                            matchesDate = targetDate.day == _selectedDate!.day &&
                                targetDate.month == _selectedDate!.month &&
                                targetDate.year == _selectedDate!.year;
                          } else {
                            matchesDate = false;
                          }
                        }
                        return matchesSearch && matchesDate;
                      }).toList();
                    }

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          _showHistory
                              ? (isAr ? 'لا يوجد سجل' : 'No history yet')
                              : (isAr ? 'لا توجد مطالبات نشطة' : 'No active claims'),
                        ),
                      );
                    }

                    // Sort by date
                    docs.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      final aTime = aData['redeemedAt'] as Timestamp? ?? aData['claimedAt'] as Timestamp?;
                      final bTime = bData['redeemedAt'] as Timestamp? ?? bData['claimedAt'] as Timestamp?;
                      return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
                    });

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        final offerTitle = data['offerTitle'] ?? 'Unknown Offer';
                        final customerUid = data['userUid'] ?? '';
                        final status = data['status'] ?? 'unknown';
                        final redeemedAt = (data['redeemedAt'] as Timestamp?)?.toDate();
                        final pickupCode = data['pickupCode'] ?? '---';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          // 🆕 Card Border
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      status == 'redeemed' ? Icons.check_circle : Icons.schedule,
                                      color: status == 'redeemed' ? Colors.green : Colors.orange,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        offerTitle,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Customer ID: $customerUid', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text('PIN: $pickupCode', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(
                                  'Status: ${status.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: status == 'redeemed' ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (status == 'redeemed' && redeemedAt != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Redeemed: ${redeemedAt.day}/${redeemedAt.month}/${redeemedAt.year} - ${redeemedAt.hour}:${redeemedAt.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
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
      },
    );
  }
}