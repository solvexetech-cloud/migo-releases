import 'package:cloud_firestore/cloud_firestore.dart';

/// Claim status:
/// - active   → claimed, not yet redeemed
/// - redeemed → QR scanned by business
/// - expired  → end date passed without redemption
/// - cancelled → user cancelled before redemption
enum ClaimStatus { active, redeemed, expired, cancelled }

ClaimStatus claimStatusFromString(String? s) {
  switch (s) {
    case 'redeemed':
      return ClaimStatus.redeemed;
    case 'expired':
      return ClaimStatus.expired;
    case 'cancelled':
      return ClaimStatus.cancelled;
    default:
      return ClaimStatus.active;
  }
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
      case ClaimStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// A user's claim of an offer (Firestore: claims/{id}).
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
    required this.claimedAt,
    required this.expiresAt,
    this.status = ClaimStatus.active,
    this.redeemedAt,
    this.redeemedBy,
    this.source = 'home',
    this.referrerUid,          // ← പുതിയത്
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
  final DateTime claimedAt;
  final DateTime expiresAt;
  final ClaimStatus status;
  final DateTime? redeemedAt;
  final String? redeemedBy;
  final String source;
  final String? referrerUid;    // ← പുതിയത്

  double get savings => originalPrice - offerPrice;

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
      claimedAt: (map['claimedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 1)),
      status: claimStatusFromString(map['status'] as String?),
      redeemedAt: (map['redeemedAt'] as Timestamp?)?.toDate(),
      redeemedBy: map['redeemedBy'] as String?,
      source: (map['source'] ?? 'home') as String,
      referrerUid: map['referrerUid'] as String?,
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
      'claimedAt': Timestamp.fromDate(claimedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status.id,
      'redeemedAt': redeemedAt != null ? Timestamp.fromDate(redeemedAt!) : null,
      'redeemedBy': redeemedBy,
      'source': source,
      'referrerUid': referrerUid,
    };
  }
}