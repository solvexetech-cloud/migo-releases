import 'package:cloud_firestore/cloud_firestore.dart';

/// Referral status:
/// - pending  → referred user signed up but hasn't claimed yet
/// - rewarded → referred user completed first claim, both got coins
/// - rejected → self-referral or suspicious
enum ReferralStatus { pending, rewarded, rejected }

ReferralStatus referralStatusFromString(String? s) {
  switch (s) {
    case 'rewarded':
      return ReferralStatus.rewarded;
    case 'rejected':
      return ReferralStatus.rejected;
    default:
      return ReferralStatus.pending;
  }
}

extension ReferralStatusX on ReferralStatus {
  String get id => name;
  String get label {
    switch (this) {
      case ReferralStatus.pending:
        return 'Pending';
      case ReferralStatus.rewarded:
        return 'Rewarded';
      case ReferralStatus.rejected:
        return 'Rejected';
    }
  }
}

/// A referral record（Firestore: referrals/{id}）.
class ReferralModel {
  const ReferralModel({
    required this.id,
    required this.referrerUid,
    required this.referralCode,
    required this.referredUid,
    required this.referredEmail,
    required this.createdAt,
    this.status = ReferralStatus.pending,
    this.referredFirstClaimAt,
    this.rewardedAt,
    this.referrerReward = 50,
    this.referredReward = 30,
  });

  final String id;
  final String referrerUid;
  final String referralCode;
  final String referredUid;
  final String referredEmail;
  final DateTime createdAt;
  final ReferralStatus status;
  final DateTime? referredFirstClaimAt;
  final DateTime? rewardedAt;
  final int referrerReward;
  final int referredReward;

  factory ReferralModel.fromMap(String id, Map<String, dynamic> map) {
    return ReferralModel(
      id: id,
      referrerUid: (map['referrerUid'] ?? '') as String,
      referralCode: (map['referralCode'] ?? '') as String,
      referredUid: (map['referredUid'] ?? '') as String,
      referredEmail: (map['referredEmail'] ?? '') as String,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: referralStatusFromString(map['status'] as String?),
      referredFirstClaimAt:
          (map['referredFirstClaimAt'] as Timestamp?)?.toDate(),
      rewardedAt: (map['rewardedAt'] as Timestamp?)?.toDate(),
      referrerReward: (map['referrerReward'] as num? ?? 50).toInt(),
      referredReward: (map['referredReward'] as num? ?? 30).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'referrerUid': referrerUid,
      'referralCode': referralCode,
      'referredUid': referredUid,
      'referredEmail': referredEmail,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.id,
      'referredFirstClaimAt': referredFirstClaimAt != null
          ? Timestamp.fromDate(referredFirstClaimAt!)
          : null,
      'rewardedAt':
          rewardedAt != null ? Timestamp.fromDate(rewardedAt!) : null,
      'referrerReward': referrerReward,
      'referredReward': referredReward,
    };
  }
}