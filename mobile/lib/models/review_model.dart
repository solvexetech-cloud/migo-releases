import 'package:cloud_firestore/cloud_firestore.dart';

/// A review of a business, usually tied to a specific claim.
/// Firestore: reviews/{id}
class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.userUid,
    required this.userDisplayName,
    required this.businessId,
    required this.businessName,
    required this.rating,
    required this.comment,
    this.claimId,
    this.offerId,
    this.offerTitle,
    this.verifiedVisit = false,
    this.imageUrls = const [],
    this.helpfulCount = 0,
    this.status = 'published', // published | hidden
    this.createdAt,
  });

  final String id;
  final String userUid;
  final String userDisplayName;
  final String businessId;
  final String businessName;
  final int rating; // 1..5
  final String comment;
  final String? claimId;
  final String? offerId;
  final String? offerTitle;
  final bool verifiedVisit;
  final List<String> imageUrls;
  final int helpfulCount;
  final String status;
  final DateTime? createdAt;

  factory ReviewModel.newDraft({
    required String userUid,
    required String userDisplayName,
    required String businessId,
    required String businessName,
    required int rating,
    required String comment,
    String? claimId,
    String? offerId,
    String? offerTitle,
    bool verifiedVisit = false,
  }) {
    return ReviewModel(
      id: '',
      userUid: userUid,
      userDisplayName: userDisplayName,
      businessId: businessId,
      businessName: businessName,
      rating: rating.clamp(1, 5),
      comment: comment.trim(),
      claimId: claimId,
      offerId: offerId,
      offerTitle: offerTitle,
      verifiedVisit: verifiedVisit,
      createdAt: DateTime.now(),
    );
  }

  factory ReviewModel.fromMap(String id, Map<String, dynamic> map) {
    return ReviewModel(
      id: id,
      userUid: (map['userUid'] ?? '') as String,
      userDisplayName: (map['userDisplayName'] ?? 'MIGO User') as String,
      businessId: (map['businessId'] ?? '') as String,
      businessName: (map['businessName'] ?? '') as String,
      rating: (map['rating'] as num? ?? 0).toInt(),
      comment: (map['comment'] ?? '') as String,
      claimId: map['claimId'] as String?,
      offerId: map['offerId'] as String?,
      offerTitle: map['offerTitle'] as String?,
      verifiedVisit: (map['verifiedVisit'] ?? false) as bool,
      imageUrls:
          List<String>.from((map['imageUrls'] as List?) ?? const []),
      helpfulCount: (map['helpfulCount'] as num? ?? 0).toInt(),
      status: (map['status'] ?? 'published') as String,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userUid': userUid,
      'userDisplayName': userDisplayName,
      'businessId': businessId,
      'businessName': businessName,
      'rating': rating,
      'comment': comment,
      'claimId': claimId,
      'offerId': offerId,
      'offerTitle': offerTitle,
      'verifiedVisit': verifiedVisit,
      'imageUrls': imageUrls,
      'helpfulCount': helpfulCount,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}