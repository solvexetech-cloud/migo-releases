import 'package:cloud_firestore/cloud_firestore.dart';

/// Creator status
enum CreatorStatus { pending, approved, rejected, suspended }

CreatorStatus creatorStatusFromString(String? s) {
  switch (s) {
    case 'approved':
      return CreatorStatus.approved;
    case 'rejected':
      return CreatorStatus.rejected;
    case 'suspended':
      return CreatorStatus.suspended;
    default:
      return CreatorStatus.pending;
  }
}

extension CreatorStatusX on CreatorStatus {
  String get id => name;
  String get label {
    switch (this) {
      case CreatorStatus.pending:
        return 'Pending';
      case CreatorStatus.approved:
        return 'Approved';
      case CreatorStatus.rejected:
        return 'Rejected';
      case CreatorStatus.suspended:
        return 'Suspended';
    }
  }
}

/// MIGO Creator / Vlogger (Firestore: creators/{uid})
class CreatorModel {
  const CreatorModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.bio = '',
    this.profileImageUrl,
    this.channelUrl,
    this.category = 'general',
    this.followers = 0,
    required this.referralCode,
    this.status = CreatorStatus.pending,
    this.approvedAt,
    this.totalShares = 0,
    this.totalViews = 0,
    this.totalClaims = 0,
    this.totalRedemptions = 0,
    this.coinsEarned = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final String bio;
  final String? profileImageUrl;
  final String? channelUrl;
  final String category;
  final int followers;
  final String referralCode;
  final CreatorStatus status;
  final DateTime? approvedAt;
  final int totalShares;
  final int totalViews;
  final int totalClaims;
  final int totalRedemptions;
  final int coinsEarned;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isApproved => status == CreatorStatus.approved;

  factory CreatorModel.fromMap(String uid, Map<String, dynamic> map) {
    return CreatorModel(
      uid: uid,
      displayName: (map['displayName'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      bio: (map['bio'] ?? '') as String,
      profileImageUrl: map['profileImageUrl'] as String?,
      channelUrl: map['channelUrl'] as String?,
      category: (map['category'] ?? 'general') as String,
      followers: (map['followers'] ?? 0) as int,
      referralCode: (map['referralCode'] ?? '') as String,
      status: creatorStatusFromString(map['status'] as String?),
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      totalShares: (map['totalShares'] ?? 0) as int,
      totalViews: (map['totalViews'] ?? 0) as int,
      totalClaims: (map['totalClaims'] ?? 0) as int,
      totalRedemptions: (map['totalRedemptions'] ?? 0) as int,
      coinsEarned: (map['coinsEarned'] ?? 0) as int,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'channelUrl': channelUrl,
      'category': category,
      'followers': followers,
      'referralCode': referralCode,
      'status': status.id,
      'approvedAt': approvedAt != null
          ? Timestamp.fromDate(approvedAt!)
          : null,
      'totalShares': totalShares,
      'totalViews': totalViews,
      'totalClaims': totalClaims,
      'totalRedemptions': totalRedemptions,
      'coinsEarned': coinsEarned,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  CreatorModel copyWith({
    String? displayName,
    String? bio,
    String? profileImageUrl,
    String? channelUrl,
    String? category,
    int? followers,
    CreatorStatus? status,
    DateTime? approvedAt,
    int? totalShares,
    int? totalViews,
    int? totalClaims,
    int? totalRedemptions,
    int? coinsEarned,
  }) {
    return CreatorModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      channelUrl: channelUrl ?? this.channelUrl,
      category: category ?? this.category,
      followers: followers ?? this.followers,
      referralCode: referralCode,
      status: status ?? this.status,
      approvedAt: approvedAt ?? this.approvedAt,
      totalShares: totalShares ?? this.totalShares,
      totalViews: totalViews ?? this.totalViews,
      totalClaims: totalClaims ?? this.totalClaims,
      totalRedemptions: totalRedemptions ?? this.totalRedemptions,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}