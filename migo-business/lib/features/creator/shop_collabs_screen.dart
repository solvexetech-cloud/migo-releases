import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/migo_theme.dart';

class ShopCollabsScreen extends StatefulWidget {
  final String businessId;
  const ShopCollabsScreen({super.key, required this.businessId});

  @override
  State<ShopCollabsScreen> createState() => _ShopCollabsScreenState();
}

class _ShopCollabsScreenState extends State<ShopCollabsScreen> {
  final Map<String, Future<Map<String, dynamic>?>> _creatorFutures = {};
  final Map<String, Future<String>> _offerFutures = {};

  Future<Map<String, dynamic>?> _creator(String userId) {
    return _creatorFutures.putIfAbsent(userId, () async {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('creators')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();
        if (snap.docs.isEmpty) return null;
        return snap.docs.first.data();
      } catch (_) {
        return null;
      }
    });
  }

  Future<String> _offerTitle(String offerId) {
    return _offerFutures.putIfAbsent(offerId, () async {
      try {
        final snap = await FirebaseFirestore.instance.collection('offers').doc(offerId).get();
        return (snap.data()?['title'] ?? 'Offer').toString();
      } catch (_) {
        return 'Offer';
      }
    });
  }

  String _fmt(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate().toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'invited':
        return 'Waiting for creator';
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined by creator';
      case 'cancelled':
        return 'Cancelled';
      case 'done':
        return 'Completed';
      default:
        return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'invited':
        return Colors.orange.shade700;
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'done':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _end(String id, bool wasAccepted) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(wasAccepted ? 'End this collab?' : 'Cancel this invite?'),
        content: Text(wasAccepted
            ? 'The creator will no longer be able to add new videos for this collab.'
            : 'The creator will no longer see it as pending.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(wasAccepted ? 'End collab' : 'Cancel invite'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FirebaseFirestore.instance.collection('collabs').doc(id).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update: $e')));
    }
  }

  Widget _card(String id, Map<String, dynamic> d) {
    final status = (d['status'] ?? '').toString();
    final creatorId = (d['creatorId'] ?? '').toString();
    final offerId = (d['offerId'] ?? '').toString();
    final note = (d['dealNote'] ?? '').toString();
    final savedTitle = (d['offerTitle'] ?? '').toString();
    final ends = d['endsAt'] as Timestamp?;
    final active = status == 'invited' || status == 'accepted';
    final ended = ends != null && ends.toDate().isBefore(DateTime.now()) && active;
    final color = ended ? Colors.grey : _statusColor(status);
    final label = ended ? 'Ended' : _statusLabel(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: _creator(creatorId),
                    builder: (context, snap) {
                      final c = snap.data;
                      final name = (c?['displayName'] ?? 'Creator').toString();
                      final photo = (c?['profileImageUrl'] ?? '').toString();
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: MigoColors.accent.withValues(alpha: 0.2),
                            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                            child: photo.isEmpty
                                ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: MigoColors.primary),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.local_offer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: savedTitle.isNotEmpty
                      ? Text(savedTitle, style: const TextStyle(fontWeight: FontWeight.w600))
                      : FutureBuilder<String>(
                          future: _offerTitle(offerId),
                          builder: (context, snap) => Text(
                            snap.data ?? '...',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                ),
              ],
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Deal: $note', style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ],
            const SizedBox(height: 8),
            Text(
              'Sent ${_fmt(d['createdAt'] as Timestamp?)}   |   Ends ${_fmt(ends)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (active) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => _end(id, status == 'accepted'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(status == 'accepted' ? 'End collab' : 'Cancel invite'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('My Collabs', style: TextStyle(color: Colors.white)),
        backgroundColor: MigoColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('collabs')
            .where('shopId', isEqualTo: widget.businessId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load collabs: ${snap.error}')));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = (snap.data?.docs ?? []).toList();
          docs.sort((a, b) {
            final ta = ((a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final tb = ((b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return tb.compareTo(ta);
          });
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No collabs yet. Open Find Creators and send an invite.', textAlign: TextAlign.center),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: docs.map((d) => _card(d.id, d.data() as Map<String, dynamic>)).toList(),
          );
        },
      ),
    );
  }
}