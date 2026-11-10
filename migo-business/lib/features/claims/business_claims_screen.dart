// migo-business/lib/features/claims/business_claims_screen.dart
// UPDATED - Includes Date & Time
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/localization/locale_provider.dart';

class BusinessClaimsScreen extends StatefulWidget {
  const BusinessClaimsScreen({super.key});

  @override
  State<BusinessClaimsScreen> createState() => _BusinessClaimsScreenState();
}

class _BusinessClaimsScreenState extends State<BusinessClaimsScreen> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';
        final uid = FirebaseAuth.instance.currentUser?.uid;

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(isAr ? 'مطالبات العملاء' : 'Customer Claims', style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFF0F2B5B), foregroundColor: Colors.white,
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _showHistory = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !_showHistory ? const Color(0xFF0F2B5B) : Colors.grey.shade300,
                            foregroundColor: !_showHistory ? Colors.white : Colors.black,
                          ),
                          child: Text(isAr ? 'نشط' : 'Active'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _showHistory = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _showHistory ? const Color(0xFF0F2B5B) : Colors.grey.shade300,
                            foregroundColor: _showHistory ? Colors.white : Colors.black,
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
                        .collection('demand_claims')
                        .where('businessId', isEqualTo: uid)
                        .where('status', isEqualTo: _showHistory ? 'redeemed' : 'locked')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                      
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 80, color: Colors.blue.withValues(alpha: 0.2)),
                              const SizedBox(height: 16),
                              Text(
                                _showHistory 
                                  ? (isAr ? 'لا يوجد سجل' : 'No history yet') 
                                  : (isAr ? 'لا توجد مطالبات نشطة' : 'No active claims yet'), 
                                style: const TextStyle(fontSize: 16, color: Colors.grey)
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final data = docs[i].data() as Map<String, dynamic>;
                          final redeemedAt = (data['redeemedAt'] as Timestamp?)?.toDate();
                          
                          String redeemedString = '';
                          if (redeemedAt != null) {
                            redeemedString = '${isAr ? 'تم الاسترداد' : 'Redeemed'}: ${redeemedAt.day}/${redeemedAt.month}/${redeemedAt.year} - ${redeemedAt.hour}:${redeemedAt.minute.toString().padLeft(2, '0')}';
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['groupTitle'] ?? 'Order', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2B5B))),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.pin, size: 16, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text('PIN: ${data['pin']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                                      const Spacer(),
                                      Text('QAR ${data['totalPrice']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (_showHistory && redeemedAt != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                        const SizedBox(width: 4),
                                        Text(
                                          redeemedString,
                                          style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  if (!_showHistory)
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              isAr ? 'انتظر حتى يقدم العميل رمز QR أو PIN.' : 'Wait for the customer to provide QR or PIN.',
                                              style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
          ),
        );
      },
    );
  }
}