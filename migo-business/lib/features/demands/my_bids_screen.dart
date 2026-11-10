// migo-business/lib/features/demands/my_bids_screen.dart
// FIXED - Always shows Edit button
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/localization/app_localizations.dart';

class MyBidsScreen extends StatelessWidget {
  const MyBidsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final t = AppLocalizations.of(context)!;
        final isAr = LocaleProvider.instance.locale == 'ar';
        final uid = FirebaseAuth.instance.currentUser?.uid;

        if (uid == null) return Scaffold(body: Center(child: Text(isAr ? 'Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¬Ãƒâ„¢Ã¢â‚¬Â° ÃƒËœÃ‚ÂªÃƒËœÃ‚Â³ÃƒËœÃ‚Â¬Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Å¾ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â®Ãƒâ„¢Ã‹â€ Ãƒâ„¢Ã¢â‚¬Å¾' : 'Please sign in')));

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF6F3EE),
            appBar: AppBar(
              title: Text(isAr ? 'ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¶Ãƒâ„¢Ã…Â ' : 'My Bids', style: const TextStyle(fontWeight: FontWeight.w800)),
              backgroundColor: const Color(0xFF0F2B5B), foregroundColor: Colors.white,
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('demand_bids').where('businessId', isEqualTo: uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.gavel_outlined, size: 80, color: Colors.blue.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text(isAr ? 'Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦ ÃƒËœÃ‚ÂªÃƒâ„¢Ã¢â‚¬Å¡ÃƒËœÃ‚Â¯Ãƒâ„¢Ã¢â‚¬Â¦ ÃƒËœÃ‚Â£Ãƒâ„¢Ã…Â  ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¶ ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â¯' : 'No bids submitted yet', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _BidCard(bidId: docs[i].id, data: data, isAr: isAr, t: t);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _BidCard extends StatelessWidget {
  final String bidId;
  final Map<String, dynamic> data;
  final bool isAr;
  final AppLocalizations t;

  const _BidCard({required this.bidId, required this.data, required this.isAr, required this.t});

  @override
  Widget build(BuildContext context) {
    final offerPrice = (data['offerPrice'] as num?)?.toDouble() ?? 0.0;
    final status = data['status'] ?? 'pending';
    final authenticity = data['authenticity'] ?? 'Original';
    final fulfillmentType = data['fulfillmentType'] ?? 'Store Pickup';
    final trustScore = (data['businessTrustScore'] as num?)?.toDouble() ?? 50.0;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final deliveryDate = (data['deliveryDate'] as Timestamp?)?.toDate();
    final groupTitle = data['groupTitle'] ?? 'Unknown Demand';

    Color statusColor;
    String statusText;
    if (status == 'pending') {
      statusColor = Colors.orange;
      statusText = isAr ? 'Ãƒâ„¢Ã¢â‚¬Å¡Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â¯ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â±ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â©' : 'Under Review';
    } else if (status == 'approved' || status == 'accepted') {
      statusColor = Colors.green;
      statusText = isAr ? 'ÃƒËœÃ‚ÂªÃƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Âª ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â§Ãƒâ„¢Ã‚ÂÃƒâ„¢Ã¢â‚¬Å¡ÃƒËœÃ‚Â©' : 'Approved';
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusText = isAr ? 'Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â±Ãƒâ„¢Ã‚ÂÃƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¶' : 'Rejected';
    } else {
      statusColor = Colors.grey;
      statusText = status;
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
            // Title, Date, Edit Icon, Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupTitle,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2B5B)),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            createdAt != null ? '${createdAt.day}/${createdAt.month}/${createdAt.year}' : 'Unknown',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          if (deliveryDate != null) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.local_shipping, size: 12, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              '${deliveryDate.day}/${deliveryDate.month}/${deliveryDate.year}',
                              style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor.withValues(alpha: 0.5))),
                  child: Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                ),
                // ÃƒÂ°Ã…Â¸Ã¢â‚¬Â Ã¢â‚¬Â¢ ALWAYS SHOW EDIT BUTTON
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                  onPressed: () => _showEditBidDialog(context, bidId, data, isAr, t),
                  tooltip: isAr ? 'ÃƒËœÃ‚ÂªÃƒËœÃ‚Â¹ÃƒËœÃ‚Â¯Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Å¾ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶' : 'Edit Bid',
                ),
              ],
            ),
            
            const Divider(height: 24),

            // Price & Trust
            Row(
              children: [
                Text('QAR ${offerPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F2B5B))),
                const Spacer(),
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${trustScore.toStringAsFixed(1)}/100', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Tags
            Row(
              children: [
                _InfoChip(icon: authenticity == 'Original' ? Icons.verified : Icons.content_copy, label: authenticity, color: authenticity == 'Original' ? Colors.green : Colors.orange),
                const SizedBox(width: 8),
                _InfoChip(icon: fulfillmentType == 'Home Delivery' ? Icons.delivery_dining : Icons.storefront, label: fulfillmentType, color: Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBidDialog(BuildContext context, String bidId, Map<String, dynamic> data, bool isAr, AppLocalizations t) {
    final formKey = GlobalKey<FormState>();
    final previousPrice = data['offerPrice'] ?? 0;
    final priceController = TextEditingController(text: previousPrice.toString());
    final authController = TextEditingController(text: data['authenticity'] ?? 'Original');
    final fulfillmentController = TextEditingController(text: data['fulfillmentType'] ?? 'Store Pickup');
    final minCommitmentsController = TextEditingController(text: (data['minCommitments'] ?? 1).toString());
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isAr ? 'ÃƒËœÃ‚ÂªÃƒËœÃ‚Â¹ÃƒËœÃ‚Â¯Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Å¾ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶' : 'Edit Bid', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(isAr ? 'ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â³ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â± ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â³ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¨Ãƒâ„¢Ã¢â‚¬Å¡: QAR $previousPrice' : 'Previous Price: QAR $previousPrice', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: isAr ? 'ÃƒËœÃ‚Â³ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±Ãƒâ„¢Ã†â€™ (QAR)' : 'Your Price (QAR)', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.attach_money)),
                        validator: (val) => (val == null || double.tryParse(val) == null) ? 'Invalid number' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: authController.text,
                        decoration: InputDecoration(labelText: isAr ? 'ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â£ÃƒËœÃ‚ÂµÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â©' : 'Authenticity', border: const OutlineInputBorder()),
                        items: [
                          DropdownMenuItem(value: 'Original', child: Text(isAr ? 'ÃƒËœÃ‚Â£ÃƒËœÃ‚ÂµÃƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã…Â ' : 'Original')),
                          DropdownMenuItem(value: 'Master Copy', child: Text(isAr ? 'Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â³ÃƒËœÃ‚Â®ÃƒËœÃ‚Â© Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â§ÃƒËœÃ‚Â³ÃƒËœÃ‚ÂªÃƒËœÃ‚Â±' : 'Master Copy')),
                        ],
                        onChanged: (val) => authController.text = val ?? 'Original',
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: fulfillmentController.text,
                        decoration: InputDecoration(labelText: isAr ? 'ÃƒËœÃ‚Â·ÃƒËœÃ‚Â±Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Å¡ÃƒËœÃ‚Â© ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚ÂªÃƒËœÃ‚Â³Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Â¦' : 'Fulfillment', border: const OutlineInputBorder()),
                        items: [
                          DropdownMenuItem(value: 'Store Pickup', child: Text(isAr ? 'ÃƒËœÃ‚Â§ÃƒËœÃ‚Â³ÃƒËœÃ‚ÂªÃƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â¦ Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã¢â‚¬Â  ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚ÂªÃƒËœÃ‚Â¬ÃƒËœÃ‚Â±' : 'Store Pickup')),
                          DropdownMenuItem(value: 'Home Delivery', child: Text(isAr ? 'ÃƒËœÃ‚ÂªÃƒâ„¢Ã‹â€ ÃƒËœÃ‚ÂµÃƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Å¾ Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â²Ãƒâ„¢Ã¢â‚¬Å¾' : 'Home Delivery')),
                        ],
                        onChanged: (val) => fulfillmentController.text = val ?? 'Store Pickup',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: minCommitmentsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: isAr ? 'ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â­ÃƒËœÃ‚Â¯ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â£ÃƒËœÃ‚Â¯Ãƒâ„¢Ã¢â‚¬Â Ãƒâ„¢Ã¢â‚¬Â° Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â´ÃƒËœÃ‚ÂªÃƒËœÃ‚Â±Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Â ' : 'Minimum Buyers Required', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.people)),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          final num = int.tryParse(val);
                          if (num == null || num < 1) return 'Min 1';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext), child: Text(isAr ? 'ÃƒËœÃ‚Â¥Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚ÂºÃƒËœÃ‚Â§ÃƒËœÃ‚Â¡' : 'Cancel')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F2B5B)),
                  onPressed: isSubmitting ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    setState(() => isSubmitting = true);
                    try {
                      await FirebaseFirestore.instance.collection('demand_bids').doc(bidId).update({
                        'offerPrice': double.parse(priceController.text),
                        'authenticity': authController.text,
                        'fulfillmentType': fulfillmentController.text,
                        'minCommitments': int.parse(minCommitmentsController.text),
                        'status': 'pending', // ÃƒÂ°Ã…Â¸Ã¢â‚¬Â Ã¢â‚¬Â¢ Reset to pending after edit
                      });
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'ÃƒËœÃ‚ÂªÃƒâ„¢Ã¢â‚¬Â¦ ÃƒËœÃ‚ÂªÃƒËœÃ‚Â­ÃƒËœÃ‚Â¯Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â« ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶ ÃƒËœÃ‚Â¨Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â§ÃƒËœÃ‚Â­!' : 'Bid updated successfully!'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    } finally {
                      if (dialogContext.mounted) setState(() => isSubmitting = false);
                    }
                  },
                  child: isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isAr ? 'ÃƒËœÃ‚ÂªÃƒËœÃ‚Â­ÃƒËœÃ‚Â¯Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â«' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}