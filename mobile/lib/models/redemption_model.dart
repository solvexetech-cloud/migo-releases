import 'package:cloud_firestore/cloud_firestore.dart';

class RedemptionModel {
  final String id;
  final String claimId;
  final String shopId;
  final String? branchId;
  final String? counterId;
  final String method; // customer_scan_counter_qr, shop_scan_claim_qr, shop_pin
  final DateTime redeemedAt;
  final double? lat;
  final double? lng;

  RedemptionModel({
    required this.id,
    required this.claimId,
    required this.shopId,
    this.branchId,
    this.counterId,
    required this.method,
    required this.redeemedAt,
    this.lat,
    this.lng,
  });

  factory RedemptionModel.fromMap(String id, Map<String, dynamic> map) {
    return RedemptionModel(
      id: id,
      claimId: map['claimId'] ?? '',
      shopId: map['shopId'] ?? '',
      branchId: map['branchId'],
      counterId: map['counterId'],
      method: map['method'] ?? '',
      redeemedAt: (map['redeemedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'claimId': claimId,
      'shopId': shopId,
      'branchId': branchId,
      'counterId': counterId,
      'method': method,
      'redeemedAt': Timestamp.fromDate(redeemedAt),
      'lat': lat,
      'lng': lng,
    };
  }
}