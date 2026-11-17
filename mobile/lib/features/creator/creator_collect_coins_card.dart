import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/migo_colors.dart';

class CreatorCollectCoinsCard extends StatefulWidget {
  final String creatorUserId;
  final VoidCallback? onCollected;
  const CreatorCollectCoinsCard({super.key, required this.creatorUserId, this.onCollected});

  @override
  State<CreatorCollectCoinsCard> createState() => _CreatorCollectCoinsCardState();
}

class _CreatorCollectCoinsCardState extends State<CreatorCollectCoinsCard> {
  bool _loading = true;
  bool _collecting = false;
  String? _error;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _eligible = [];
  int _readyCoins = 0;
  int _waitingCoins = 0;
  DateTime? _nextReady;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('creator_earnings')
          .where('creatorId', isEqualTo: widget.creatorUserId)
          .where('status', isEqualTo: 'pending')
          .get();
      final cutoff = DateTime.now().subtract(const Duration(hours: 24, minutes: 5));
      final eligible = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      var ready = 0;
      var waiting = 0;
      DateTime? next;
      for (final d in snap.docs) {
        final m = d.data();
        final coins = ((m['amount'] as num?) ?? 0).round();
        final created = (m['createdAt'] as Timestamp?)?.toDate();
        if (created == null) continue;
        if (created.isBefore(cutoff)) {
          eligible.add(d);
          ready += coins;
        } else {
          waiting += coins;
          final at = created.add(const Duration(hours: 24, minutes: 5));
          if (next == null || at.isBefore(next)) next = at;
        }
      }
      if (!mounted) return;
      setState(() {
        _eligible = eligible;
        _readyCoins = ready;
        _waitingCoins = waiting;
        _nextReady = next;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Could not load rewards: $e'; });
    }
  }

  Future<void> _collect() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _eligible.isEmpty || _collecting) return;
    setState(() { _collecting = true; _error = null; });
    try {
      var expiryDays = 60;
      try {
        final cs = await FirebaseFirestore.instance.collection('config').doc('coin_settings').get();
        expiryDays = (cs.data()?['expiryDays'] as num?)?.toInt() ?? 60;
      } catch (_) {}

      final toCollect = _eligible.take(400).toList();
      final batch = FirebaseFirestore.instance.batch();
      var total = 0;
      for (final d in toCollect) {
        total += ((d.data()['amount'] as num?) ?? 0).round();
        batch.update(d.reference, {
          'status': 'collected',
          'collectedAt': FieldValue.serverTimestamp(),
        });
      }
      if (total <= 0) {
        setState(() { _collecting = false; _error = 'Nothing to collect.'; });
        return;
      }
      final plural = toCollect.length == 1 ? '' : 's';
      batch.set(
        FirebaseFirestore.instance.collection('users').doc(uid),
        {
          'coins': FieldValue.increment(total),
          'coinsExpireAt': Timestamp.fromDate(DateTime.now().add(Duration(days: expiryDays))),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      batch.set(FirebaseFirestore.instance.collection('coin_transactions').doc(), {
        'uid': uid,
        'amount': total,
        'reason': 'Creator rewards (${toCollect.length} redemption$plural)',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+$total coins added to your wallet')),
      );
      setState(() => _collecting = false);
      await _load();
      widget.onCollected?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() { _collecting = false; _error = 'Could not collect coins: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (_error != null && _eligible.isEmpty && _waitingCoins == 0) {
      return Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12));
    }
    if (_readyCoins == 0 && _waitingCoins == 0) {
      return const SizedBox.shrink();
    }
    String holdText = '';
    if (_waitingCoins > 0 && _nextReady != null) {
      final h = _nextReady!.difference(DateTime.now()).inHours + 1;
      holdText = '$_waitingCoins coins on hold, next batch ready in about ${h < 1 ? 1 : h} h';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MigoColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MigoColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _readyCoins > 0 ? '$_readyCoins coins ready to collect' : 'Rewards are on hold for 24 hours',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          if (holdText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(holdText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          if (_readyCoins > 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _collecting ? null : _collect,
                icon: _collecting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download_done, size: 18),
                label: const Text('Collect coins', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MigoColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}