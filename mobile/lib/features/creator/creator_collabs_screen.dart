import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/migo_colors.dart';
import 'add_content_screen.dart';

class CreatorCollabsScreen extends StatefulWidget {
  const CreatorCollabsScreen({super.key});

  @override
  State<CreatorCollabsScreen> createState() => _CreatorCollabsScreenState();
}

class _CreatorCollabsScreenState extends State<CreatorCollabsScreen> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  final Set<String> _busy = {};
  final Map<String, Future<String>> _shopNames = {};
  final Map<String, Future<String>> _offerFutures = {};

  Future<String> _shopName(String shopId) {
    return _shopNames.putIfAbsent(shopId, () async {
      try {
        final snap = await FirebaseFirestore.instance.collection('businesses').doc(shopId).get();
        return (snap.data()?['name'] ?? 'Shop').toString();
      } catch (_) {
        return 'Shop';
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
        return 'New invitation';
      case 'accepted':
        return 'Active';
      case 'declined':
        return 'Declined';
      case 'cancelled':
        return 'Cancelled by shop';
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

  Future<void> _respond(String id, bool accept) async {
    setState(() => _busy.add(id));
    try {
      await FirebaseFirestore.instance.collection('collabs').doc(id).update({
        'status': accept ? 'accepted' : 'declined',
        'updatedAt': FieldValue.serverTimestamp(),
        if (accept) 'acceptedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Widget _videos(String collabId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('creator_content')
          .where('collabId', isEqualTo: collabId)
          .snapshots(),
      builder: (context, snap) {
        final vids = snap.data?.docs ?? [];
        if (vids.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text('Your videos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            ...vids.map((v) {
              final vd = v.data() as Map<String, dynamic>;
              final st = (vd['status'] ?? 'submitted').toString();
              final note = (vd['rejectNote'] ?? '').toString();
              String text;
              Color c;
              if (st == 'approved') {
                text = 'Live in Reels';
                c = Colors.green;
              } else if (st == 'rejected') {
                text = note.isNotEmpty ? 'Rejected: $note' : 'Rejected';
                c = Colors.red;
              } else if (st == 'hidden') {
                text = 'Hidden';
                c = Colors.grey;
              } else {
                text = 'Waiting for shop approval';
                c = Colors.orange.shade700;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        (vd['url'] ?? '').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c)),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _card(String uid, String id, Map<String, dynamic> d) {
    final status = (d['status'] ?? '').toString();
    final shopId = (d['shopId'] ?? '').toString();
    final offerId = (d['offerId'] ?? '').toString();
    final note = (d['dealNote'] ?? '').toString();
    final savedTitle = (d['offerTitle'] ?? '').toString();
    final ends = d['endsAt'] as Timestamp?;
    final active = status == 'invited' || status == 'accepted';
    final ended = ends != null && ends.toDate().isBefore(DateTime.now()) && active;
    final color = ended ? Colors.grey : _statusColor(status);
    final label = ended ? 'Ended' : _statusLabel(status);
    final busy = _busy.contains(id);

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
                  child: FutureBuilder<String>(
                    future: _shopName(shopId),
                    builder: (context, snap) => Text(
                      snap.data ?? '...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.local_offer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: savedTitle.isNotEmpty
                      ? Text(savedTitle, style: const TextStyle(fontWeight: FontWeight.w600))
                      : FutureBuilder<String>(
                          future: _offerTitle(offerId),
                          builder: (context, snap) =>
                              Text(snap.data ?? '...', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                ),
              ],
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Deal agreed with the shop: $note', style: const TextStyle(fontSize: 13)),
            ],
            const SizedBox(height: 8),
            Text('Ends ${_fmt(ends)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (status == 'invited' && !ended) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : () => _respond(id, false),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: busy ? null : () => _respond(id, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MigoColors.success,
                        foregroundColor: Colors.white,
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'accepted' && !ended) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddContentScreen(
                        collabId: id,
                        shopId: shopId,
                        offerId: offerId,
                        creatorId: uid,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.add_link, size: 18),
                  label: const Text('Add video link'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MigoColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tip: say clearly in your video that it is a paid partnership (#ad).',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
            _videos(id),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('My Collabs', style: TextStyle(color: Colors.white)),
        backgroundColor: MigoColors.primary,
        foregroundColor: Colors.white,
      ),
      body: uid == null
          ? const Center(child: Text('Please sign in.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('collabs')
                  .where('creatorId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Could not load collabs: ${snap.error}'),
                    ),
                  );
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
                      child: Text(
                        'No invitations yet. Shops will invite you from their MIGO Business app.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: docs.map((d) => _card(uid, d.id, d.data() as Map<String, dynamic>)).toList(),
                );
              },
            ),
    );
  }
}