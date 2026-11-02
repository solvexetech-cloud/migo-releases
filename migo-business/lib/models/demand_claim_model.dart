import 'package:cloud_firestore/cloud_firestore.dart';

class DemandClaimModel {
  final String id;
  final String demandId;
  final String bidId;
  final String userId;
  final String businessId;
  final Map<String, String> businessName;
  final double finalPrice;
  final String fulfillmentType; // 'Store Pickup', 'Home Delivery'
  
  final String? deliveryAddress;
  final String? deliveryPhone;

  final String redemptionPin; // 6-Digit PIN
  final String qrData;
  final String status; // 'locked', 'redeemed', 'cancelled'
  
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? redeemedAt;

  DemandClaimModel({
    required this.id,
    required this.demandId,
    required this.bidId,
    required this.userId,
    required this.businessId,
    required this.businessName,
    required this.finalPrice,
    required this.fulfillmentType,
    this.deliveryAddress,
    this.deliveryPhone,
    required this.redemptionPin,
    required this.qrData,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.redeemedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'demandId': demandId,
      'bidId': bidId,
      'userId': userId,
      'businessId': businessId,
      'businessName': businessName,
      'finalPrice': finalPrice,
      'fulfillmentType': fulfillmentType,
      'deliveryAddress': deliveryAddress,
      'deliveryPhone': deliveryPhone,
      'redemptionPin': redemptionPin,
      'qrData': qrData,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'redeemedAt': redeemedAt != null ? Timestamp.fromDate(redeemedAt!) : null,
    };
  }

  factory DemandClaimModel.fromMap(String id, Map<String, dynamic> map) {
    return DemandClaimModel(
      id: id,
      demandId: map['demandId'] ?? '',
      bidId: map['bidId'] ?? '',
      userId: map['userId'] ?? '',
      businessId: map['businessId'] ?? '',
      businessName: Map<String, String>.from(map['businessName'] ?? {'en': '', 'ar': ''}),
      finalPrice: (map['finalPrice'] as num?)?.toDouble() ?? 0.0,
      fulfillmentType: map['fulfillmentType'] ?? 'Store Pickup',
      deliveryAddress: map['deliveryAddress'],
      deliveryPhone: map['deliveryPhone'],
      redemptionPin: map['redemptionPin'] ?? '',
      qrData: map['qrData'] ?? '',
      status: map['status'] ?? 'locked',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 2)),
      redeemedAt: (map['redeemedAt'] as Timestamp?)?.toDate(),
    );
  }
}
