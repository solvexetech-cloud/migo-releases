import 'package:cloud_firestore/cloud_firestore.dart';

/// Group deal status:
/// - open     → gathering participants
/// - unlocked → minimum reached, deal is on
/// - failed   → deadline passed without enough participants
/// - expired  → past end date
enum GroupDealStatus { open, unlocked, failed, expired }

GroupDealStatus groupDealStatusFromString(String? s) {
  switch (s) {
    case 'unlocked':
      return GroupDealStatus.unlocked;
    case 'failed':
      return GroupDealStatus.failed;
    case 'expired':
      return GroupDealStatus.expired;
    default:
      return GroupDealStatus.open;
  }
}

extension GroupDealStatusX on GroupDealStatus {
  String get id => name;
  String get label {
    switch (this) {
      case GroupDealStatus.open:
        return 'Open';
      case GroupDealStatus.unlocked:
        return 'Unlocked';
      case GroupDealStatus.failed:
        return 'Failed';
      case GroupDealStatus.expired:
        return 'Expired';
    }
  }
}

/// A group deal tied to an Offer（Firestore: group_deals/{offerId}）.
/// Document ID equals the offer ID for easy lookup.
class GroupDealModel {
  const GroupDealModel({
    required this.offerId,
    required this.minParticipants,
    required this.maxParticipants,
    required this.deadline,
    this.status = GroupDealStatus.open,
    this.participantUids = const [],
    this.unlockedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String offerId;
  final int minParticipants;
  final int? maxParticipants;
  final DateTime deadline;
  final GroupDealStatus status;
  final List<String> participantUids;
  final DateTime? unlockedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get joinedCount => participantUids.length;

  double get progress =>
      minParticipants == 0 ? 0 : joinedCount / minParticipants;

  bool get isFull =>
      maxParticipants != null && joinedCount >= maxParticipants!;

  bool get meetsMinimum => joinedCount >= minParticipants;

  int get spotsLeft {
    if (maxParticipants == null) {
      return (minParticipants - joinedCount).clamp(0, 9999);
    }
    return (maxParticipants! - joinedCount).clamp(0, 9999);
  }

  factory GroupDealModel.newDraft({
    required String offerId,
    required int minParticipants,
    int? maxParticipants,
    required DateTime deadline,
  }) {
    final now = DateTime.now();
    return GroupDealModel(
      offerId: offerId,
      minParticipants: minParticipants,
      maxParticipants: maxParticipants,
      deadline: deadline,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory GroupDealModel.fromMap(String offerId, Map<String, dynamic> map) {
    return GroupDealModel(
      offerId: offerId,
      minParticipants: (map['minParticipants'] as num? ?? 5).toInt(),
      maxParticipants: (map['maxParticipants'] as num?)?.toInt(),
      deadline: (map['deadline'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 7)),
      status: groupDealStatusFromString(map['status'] as String?),
      participantUids:
          List<String>.from((map['participantUids'] as List?) ?? []),
      unlockedAt: (map['unlockedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'offerId': offerId,
      'minParticipants': minParticipants,
      'maxParticipants': maxParticipants,
      'deadline': Timestamp.fromDate(deadline),
      'status': status.id,
      'participantUids': participantUids,
      'unlockedAt':
          unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}