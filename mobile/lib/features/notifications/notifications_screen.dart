import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/notification_model.dart';
import '../../services/firestore_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(NotifType t) {
    switch (t) {
      case NotifType.welcome:
        return Icons.celebration_outlined;
      case NotifType.referralReward:
        return Icons.card_giftcard;
      case NotifType.coinEarned:
        return Icons.monetization_on_outlined;
      case NotifType.groupUnlocked:
        return Icons.lock_open;
      case NotifType.offerApproved:
        return Icons.check_circle_outline;
      case NotifType.offerRejected:
        return Icons.cancel_outlined;
      case NotifType.newReview:
        return Icons.rate_review_outlined;
      case NotifType.claimReminder:
        return Icons.schedule;
      case NotifType.system:
        return Icons.info_outline;
    }
  }

  Color _colorFor(NotifType t) {
    switch (t) {
      case NotifType.referralReward:
      case NotifType.coinEarned:
        return MigoColors.accent;
      case NotifType.groupUnlocked:
      case NotifType.offerApproved:
        return MigoColors.success;
      case NotifType.offerRejected:
        return MigoColors.error;
      case NotifType.newReview:
        return MigoColors.primary;
      default:
        return MigoColors.primaryLight;
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await FirestoreService.instance
                  .markAllNotificationsRead(uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All marked as read')),
                );
              }
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream:
            FirestoreService.instance.streamMyNotifications(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: MigoColors.textSecondaryLight,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your activity and rewards will show here.',
                      style: TextStyle(
                        fontSize: 13,
                        color: MigoColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final n = list[i];
              return InkWell(
                onTap: () async {
                  if (!n.read) {
                    await FirestoreService.instance
                        .markNotificationRead(n.id);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: n.read
                        ? MigoColors.surfaceLight
                        : MigoColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: n.read
                          ? MigoColors.dividerLight
                          : MigoColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _colorFor(n.type).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconFor(n.type),
                          size: 18,
                          color: _colorFor(n.type),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: n.read
                                          ? FontWeight.w600
                                          : FontWeight.w800,
                                      color:
                                          MigoColors.textPrimaryLight,
                                    ),
                                  ),
                                ),
                                if (!n.read)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: MigoColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n.body,
                              style: const TextStyle(
                                fontSize: 12,
                                color: MigoColors.textSecondaryLight,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _timeAgo(n.createdAt),
                              style: const TextStyle(
                                fontSize: 10,
                                color: MigoColors.textSecondaryLight,
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
    );
  }
}