import 'package:cloud_firestore/cloud_firestore.dart';

class CreatorContentModel {
  final String id;
  final String collabId;
  final String creatorId;
  final String shopId;
  final String offerId;
  final String platform; // instagram, tiktok, youtube
  final String url;
  final String? thumbnailUrl;
  final String? caption;
  final bool disclosureConfirmed;
  final String status; // submitted, approved, rejected, hidden
  final String? rejectNote;
  final int viewsCount;
  final int likesCount;
  final DateTime createdAt;

  CreatorContentModel({
    required this.id,
    required this.collabId,
    required this.creatorId,
    required this.shopId,
    required this.offerId,
    required this.platform,
    required this.url,
    this.thumbnailUrl,
    this.caption,
    required this.disclosureConfirmed,
    required this.status,
    this.rejectNote,
    required this.viewsCount,
    required this.likesCount,
    required this.createdAt,
  });

  factory CreatorContentModel.fromMap(String id, Map<String, dynamic> map) {
    return CreatorContentModel(
      id: id,
      collabId: map['collabId'] ?? '',
      creatorId: map['creatorId'] ?? '',
      shopId: map['shopId'] ?? '',
      offerId: map['offerId'] ?? '',
      platform: map['platform'] ?? '',
      url: map['url'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      caption: map['caption'],
      disclosureConfirmed: map['disclosureConfirmed'] ?? false,
      status: map['status'] ?? 'submitted',
      rejectNote: map['rejectNote'],
      viewsCount: (map['viewsCount'] as num? ?? 0).toInt(),
      likesCount: (map['likesCount'] as num? ?? 0).toInt(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'collabId': collabId,
      'creatorId': creatorId,
      'shopId': shopId,
      'offerId': offerId,
      'platform': platform,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'disclosureConfirmed': disclosureConfirmed,
      'status': status,
      'rejectNote': rejectNote,
      'viewsCount': viewsCount,
      'likesCount': likesCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}