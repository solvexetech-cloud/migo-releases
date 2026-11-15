import 'package:cloud_firestore/cloud_firestore.dart';

enum CreatorStatus {
  pending,
  approved,
  rejected,
  suspended,
}

extension CreatorStatusX on CreatorStatus {
  String get id => name;
}

CreatorStatus creatorStatusFromString(String? s) {
  switch (s) {
    case 'approved': return CreatorStatus.approved;
    case 'rejected': return CreatorStatus.rejected;
    case 'suspended': return CreatorStatus.suspended;
    default: return CreatorStatus.pending;
  }
}

class CreatorModel {
  final String id;
  final String userId;
  final String displayName;
  final String bio;
  final String? profileImageUrl;
  final String city;
  final String category;
  final List<String> categories;
  final String phoneOrWhatsapp;
  final String? instagramUrl;
  final String? tiktokUrl;
  final String? youtubeUrl;
  final String? channelUrl;
  final int followers;
  final int followersCount;
  final CreatorStatus status;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final DateTime createdAt;
  
  final int totalViews;
  final int totalClaims;
  final int totalRedemptions;
  final int totalShares;
  final int coinsEarned;
  final String referralCode;

  CreatorModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.bio,
    this.profileImageUrl,
    required this.city,
    required this.category,
    required this.categories,
    required this.phoneOrWhatsapp,
    this.instagramUrl,
    this.tiktokUrl,
    this.youtubeUrl,
    this.channelUrl,
    required this.followers,
    required this.followersCount,
    required this.status,
    this.rejectionReason,
    this.approvedAt,
    required this.createdAt,
    required this.totalViews,
    required this.totalClaims,
    required this.totalRedemptions,
    required this.totalShares,
    required this.coinsEarned,
    required this.referralCode,
  });

  bool get isApproved => status == CreatorStatus.approved;

  factory CreatorModel.fromMap(String id, Map<String, dynamic> map) {
    return CreatorModel(
      id: id,
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      bio: map['bio'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      city: map['city'] ?? '',
      category: map['category'] ?? '',
      categories: List<String>.from(map['categories'] ?? []),
      phoneOrWhatsapp: map['phoneOrWhatsapp'] ?? '',
      instagramUrl: map['instagramUrl'],
      tiktokUrl: map['tiktokUrl'],
      youtubeUrl: map['youtubeUrl'],
      channelUrl: map['channelUrl'],
      followers: (map['followers'] as num? ?? 0).toInt(),
      followersCount: (map['followersCount'] as num? ?? 0).toInt(),
      status: creatorStatusFromString(map['status'] as String?),
      rejectionReason: map['rejectionReason'],
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalViews: (map['totalViews'] as num? ?? 0).toInt(),
      totalClaims: (map['totalClaims'] as num? ?? 0).toInt(),
      totalRedemptions: (map['totalRedemptions'] as num? ?? 0).toInt(),
      totalShares: (map['totalShares'] as num? ?? 0).toInt(),
      coinsEarned: (map['coinsEarned'] as num? ?? 0).toInt(),
      referralCode: map['referralCode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'city': city,
      'category': category,
      'categories': categories,
      'phoneOrWhatsapp': phoneOrWhatsapp,
      'instagramUrl': instagramUrl,
      'tiktokUrl': tiktokUrl,
      'youtubeUrl': youtubeUrl,
      'channelUrl': channelUrl,
      'followers': followers,
      'followersCount': followersCount,
      'status': status.id,
      'rejectionReason': rejectionReason,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'totalViews': totalViews,
      'totalClaims': totalClaims,
      'totalRedemptions': totalRedemptions,
      'totalShares': totalShares,
      'coinsEarned': coinsEarned,
      'referralCode': referralCode,
    };
  }
}