import 'package:cloud_firestore/cloud_firestore.dart';

class CollabModel {
  final String id;
  final String shopId;
  final String creatorId;
  final String offerId;
  final double feePerRedemption;
  final String currency;
  final DateTime? endsAt;
  final String status; // invited, accepted, done, cancelled
  final DateTime createdAt;
  final DateTime? acceptedAt;

  CollabModel({
    required this.id,
    required this.shopId,
    required this.creatorId,
    required this.offerId,
    required this.feePerRedemption,
    required this.currency,
    this.endsAt,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
  });

  factory CollabModel.fromMap(String id, Map<String, dynamic> map) {
    return CollabModel(
      id: id,
      shopId: map['shopId'] ?? '',
      creatorId: map['creatorId'] ?? '',
      offerId: map['offerId'] ?? '',
      feePerRedemption: (map['feePerRedemption'] as num? ?? 0).toDouble(),
      currency: map['currency'] ?? 'QAR',
      endsAt: (map['endsAt'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'invited',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'creatorId': creatorId,
      'offerId': offerId,
      'feePerRedemption': feePerRedemption,
      'currency': currency,
      'endsAt': endsAt != null ? Timestamp.fromDate(endsAt!) : null,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
    };
  }
}