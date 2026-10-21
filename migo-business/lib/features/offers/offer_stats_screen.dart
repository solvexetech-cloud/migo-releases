import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/migo_theme.dart';

class OfferStatsScreen extends StatelessWidget {
  final String offerId;
  final String offerTitle;

  const OfferStatsScreen({super.key, required this.offerId, required this.offerTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(offerTitle)),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('claims')
            .where('offerId', isEqualTo: offerId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          
          int active = 0;
          int redeemed = 0;
          for (var doc in docs) {
            final status = (doc.data() as Map<String, dynamic>)['status'];
            if (status == 'active') active++;
            if (status == 'redeemed') redeemed++;
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Claim Statistics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _statTile('Total Claims', '${docs.length}', Colors.blue),
                _statTile('Active Claims', '$active', Colors.orange),
                _statTile('Redeemed Claims', '$redeemed', MigoColors.success),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(Icons.circle, color: color, size: 12),
        title: Text(label),
        trailing: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}