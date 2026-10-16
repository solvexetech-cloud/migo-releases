// ═══════════════════════════════════════════════════════
// MIGO Business — No-Show History Screen
// ═══════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NoShowHistoryScreen extends StatefulWidget {
  final String businessId;

  const NoShowHistoryScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<NoShowHistoryScreen> createState() => _NoShowHistoryScreenState();
}

class _NoShowHistoryScreenState extends State<NoShowHistoryScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('No-Show History'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('no_show_log')
            .where('businessId', isEqualTo: widget.businessId)
            .orderBy('timestamp', descending: true)
            .limit(200)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }

          final all = snapshot.data?.docs ?? [];

          final filtered = all.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final ts = (data['timestamp'] as Timestamp?)?.toDate();
            if (ts == null) return false;

            if (_filter == 'all') return true;
            if (_filter == 'week') {
              return DateTime.now().difference(ts).inDays <= 7;
            }
            if (_filter == 'month') {
              return DateTime.now().difference(ts).inDays <= 30;
            }
            return true;
          }).toList();

          final uniqueUsers =
              all.map((d) => (d.data() as Map)['userUid']).toSet().length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        icon: '🚫',
                        label: 'Total No-Shows',
                        value: all.length.toString(),
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        icon: '👤',
                        label: 'Unique Users',
                        value: uniqueUsers.toString(),
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _filterButton('all', 'All'),
                    const SizedBox(width: 8),
                    _filterButton('week', 'Last 7 days'),
                    const SizedBox(width: 8),
                    _filterButton('month', 'Last 30 days'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: Colors.green.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No no-shows recorded',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your customers are showing up!',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => setState(() {}),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final data = filtered[index].data()
                                as Map<String, dynamic>;
                            return _noShowCard(data);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String key, String label) {
    final active = _filter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF7C3AED) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? const Color(0xFF7C3AED)
                  : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _noShowCard(Map<String, dynamic> data) {
    final userName = data['userName'] as String? ?? 'Customer';
    final userUid = data['userUid'] as String? ?? '';
    final offerId = data['offerId'] as String? ?? '';
    final reason = data['reason'] as String? ?? 'expired';
    final ts = (data['timestamp'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.timer_off,
              color: Colors.red.shade600,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Offer: ${offerId.isNotEmpty ? offerId.substring(0, offerId.length > 8 ? 8 : offerId.length) : "—"}...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (userUid.isNotEmpty)
                  Text(
                    'UID: ${userUid.substring(0, 8)}...',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: reason == 'manual'
                      ? Colors.orange.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  reason.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: reason == 'manual'
                        ? Colors.orange.shade800
                        : Colors.red.shade800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (ts != null)
                Text(
                  _formatDate(ts),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}