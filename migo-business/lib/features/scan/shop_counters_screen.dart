import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShopCountersScreen extends StatefulWidget {
  final String businessId;
  const ShopCountersScreen({super.key, required this.businessId});

  @override
  State<ShopCountersScreen> createState() => _ShopCountersScreenState();
}

class _ShopCountersScreenState extends State<ShopCountersScreen> {
  void _addCounter() async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Counter'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Counter Name (e.g. Counter 1)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final token = DateTime.now().millisecondsSinceEpoch.toString() + widget.businessId.substring(0, 4);
              await FirebaseFirestore.instance.collection('branch_counters').add({
                'businessId': widget.businessId,
                'name': nameController.text.trim(),
                'token': token,
                'active': true,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Counters'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCounter,
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Counter', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('branch_counters')
            .where('businessId', isEqualTo: widget.businessId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No counters found. Add one to get started.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final token = data['token'] ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        data['name'] ?? 'Counter',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (token.isNotEmpty)
                        QrImageView(
                          data: 'MIGO-COUNTER-$token',
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Show this to a customer to redeem their offer.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}