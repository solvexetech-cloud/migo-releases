import 'package:cloud_firestore/cloud_firestore.dart';

enum ClaimStatus {
  active,
  redeemed,
  expired,
}

extension ClaimStatusX on ClaimStatus {
  String get id => name;
  
  String get label {
    switch (this) {
      case ClaimStatus.active:
        return 'Active';
      case ClaimStatus.redeemed:
        return 'Redeemed';
      case ClaimStatus.expired:
        return 'Expired';
    }
  }
}

ClaimStatus claimStatusFromString(String? s) {
  switch (s) {
    case 'redeemed':
      return ClaimStatus.redeemed;
    case 'expired':
      return ClaimStatus.expired;
    default:
      return ClaimStatus.active;
  }
}

class ClaimModel {
  const ClaimModel({
    required this.id,
    required this.userUid,
    required this.businessId,
    required this.businessName,
    required this.offerId,
    required this.offerTitle,
    required this.currency,
    required this.originalPrice,
    required this.offerPrice,
    this.pickupCode, // ðŸ†• PIN / Pickup Code
    required this.status,
    required this.claimedAt,
    required this.expiresAt,
    this.redeemedAt,
    this.redeemedBy,
    this.source,
    this.creatorId,
    this.collabId,
    this.contentId,
  });

  final String id;
  final String userUid;
  final String businessId;
  final String businessName;
  final String offerId;
  final String offerTitle;
  final String currency;
  final double originalPrice;
  final double offerPrice;
  
  final String? pickupCode; // ðŸ†• PIN / Pickup Code
  
  final ClaimStatus status;
  final DateTime claimedAt;
  final DateTime expiresAt;
  final DateTime? redeemedAt;
  final String? redeemedBy;
  final String? source;
  final String? creatorId;
  final String? collabId;
  final String? contentId;

  factory ClaimModel.fromMap(String id, Map<String, dynamic> map) {
    return ClaimModel(
      id: id,
      userUid: (map['userUid'] ?? '') as String,
      businessId: (map['businessId'] ?? '') as String,
      businessName: (map['businessName'] ?? '') as String,
      offerId: (map['offerId'] ?? '') as String,
      offerTitle: (map['offerTitle'] ?? '') as String,
      currency: (map['currency'] ?? 'QAR') as String,
      originalPrice: (map['originalPrice'] as num? ?? 0).toDouble(),
      offerPrice: (map['offerPrice'] as num? ?? 0).toDouble(),
      pickupCode: map['pickupCode'] as String?, // ðŸ†• à´®à´¾à´ªàµà´ªà´¿àµ½ à´¨à´¿à´¨àµà´¨àµ à´Žà´Ÿàµà´•àµà´•àµà´¨àµà´¨àµ
      status: claimStatusFromString(map['status'] as String?),
      claimedAt: (map['claimedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      redeemedAt: (map['redeemedAt'] as Timestamp?)?.toDate(),
      redeemedBy: map['redeemedBy'] as String?,
      source: map['source'] as String?,
      creatorId: map['creatorId'] as String?,
      collabId: map['collabId'] as String?,
      contentId: map['contentId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userUid': userUid,
      'businessId': businessId,
      'businessName': businessName,
      'offerId': offerId,
      'offerTitle': offerTitle,
      'currency': currency,
      'originalPrice': originalPrice,
      'offerPrice': offerPrice,
      'pickupCode': pickupCode, // ðŸ†• à´¡à´¾à´±àµà´±à´¾à´¬àµ‡à´¸à´¿à´²àµ‡à´•àµà´•àµ à´¸àµ‡à´µàµ à´šàµ†à´¯àµà´¯àµà´¨àµà´¨àµ
      'status': status.id,
      'claimedAt': Timestamp.fromDate(claimedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'redeemedAt': redeemedAt != null ? Timestamp.fromDate(redeemedAt!) : null,
      'redeemedBy': redeemedBy,
      'source': source,
      'creatorId': creatorId,
      'collabId': collabId,
      'contentId': contentId,
    };
  }
}