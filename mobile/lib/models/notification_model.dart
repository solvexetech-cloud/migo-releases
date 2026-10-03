import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification types — map to icons and deep-link targets.
enum NotifType {
  welcome,
  referralReward,
  coinEarned,
  groupUnlocked,
  offerApproved,
  offerRejected,
  newReview,
  claimReminder,
  system,
}

NotifType notifTypeFromString(String? s) {
  switch (s) {
    case 'welcome':
      return NotifType.welcome;
    case 'referral_reward':
      return NotifType.referralReward;
    case 'coin_earned':
      return NotifType.coinEarned;
    case 'group_unlocked':
      return NotifType.groupUnlocked;
    case 'offer_approved':
      return NotifType.offerApproved;
    case 'offer_rejected':
      return NotifType.offerRejected;
    case 'new_review':
      return NotifType.newReview;
    case 'claim_reminder':
      return NotifType.claimReminder;
    default:
      return NotifType.system;
  }
}

extension NotifTypeX on NotifType {
  String get id {
    switch (this) {
      case NotifType.welcome:
        return 'welcome';
      case NotifType.referralReward:
        return 'referral_reward';
      case NotifType.coinEarned:
        return 'coin_earned';
      case NotifType.groupUnlocked:
        return 'group_unlocked';
      case NotifType.offerApproved:
        return 'offer_approved';
      case NotifType.offerRejected:
        return 'offer_rejected';
      case NotifType.newReview:
        return 'new_review';
      case NotifType.claimReminder:
        return 'claim_reminder';
      case NotifType.system:
        return 'system';
    }
  }
}

/// An in-app notification（Firestore: notifications/{id}）.
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userUid,
    required this.type,
    required this.title,
    required this.body,
    this.read = false,
    this.targetRoute, // e.g. "wallet", "claim/xyz", "business"
    this.targetId, // id for the route
    this.createdAt,
  });

  final String id;
  final String userUid;
  final NotifType type;
  final String title;
  final String body;
  final bool read;
  final String? targetRoute;
  final String? targetId;
  final DateTime? createdAt;

  factory NotificationModel.newDraft({
    required String userUid,
    required NotifType type,
    required String title,
    required String body,
    String? targetRoute,
    String? targetId,
  }) {
    return NotificationModel(
      id: '',
      userUid: userUid,
      type: type,
      title: title,
      body: body,
      targetRoute: targetRoute,
      targetId: targetId,
      createdAt: DateTime.now(),
    );
  }

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      userUid: (map['userUid'] ?? '') as String,
      type: notifTypeFromString(map['type'] as String?),
      title: (map['title'] ?? '') as String,
      body: (map['body'] ?? '') as String,
      read: (map['read'] ?? false) as bool,
      targetRoute: map['targetRoute'] as String?,
      targetId: map['targetId'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userUid': userUid,
      'type': type.id,
      'title': title,
      'body': body,
      'read': read,
      'targetRoute': targetRoute,
      'targetId': targetId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}