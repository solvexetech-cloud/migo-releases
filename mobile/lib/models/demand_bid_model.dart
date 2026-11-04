import 'package:cloud_firestore/cloud_firestore.dart';

class DemandBidModel {
  final String id;
  final String demandId;
  final String businessId;
  final Map<String, String> businessName;
  final double offerPrice;
  final String authenticity; // 'Original', 'Master Copy'
  final String fulfillmentType; // 'Store Pickup', 'Home Delivery'
  final String status; // 'pending', 'approved', 'rejected'
  final double businessTrustScore;
  final Map<String, String> adminNotes;
  final DateTime createdAt;
  final int minCommitments; // 🆕 എത്ര പേർ വാങ്ങണം
  final int commitCount; // 🆕 ഇപ്പോൾ എത്ര പേർ തയ്യാറായി

  DemandBidModel({
    required this.id,
    required this.demandId,
    required this.businessId,
    required this.businessName,
    required this.offerPrice,
    required this.authenticity,
    required this.fulfillmentType,
    required this.status,
    required this.businessTrustScore,
    required this.adminNotes,
    required this.createdAt,
    required this.minCommitments, // 🆕
    this.commitCount = 0, // 🆕
  });

  Map<String, dynamic> toMap() {
    return {
      'demandId': demandId,
      'businessId': businessId,
      'businessName': businessName,
      'offerPrice': offerPrice,
      'authenticity': authenticity,
      'fulfillmentType': fulfillmentType,
      'status': status,
      'businessTrustScore': businessTrustScore,
      'adminNotes': adminNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'minCommitments': minCommitments, // 🆕
      'commitCount': commitCount, // 🆕
    };
  }

  factory DemandBidModel.fromMap(String id, Map<String, dynamic> map) {
    return DemandBidModel(
      id: id,
      demandId: map['demandId'] ?? '',
      businessId: map['businessId'] ?? '',
      businessName: Map<String, String>.from(map['businessName'] ?? {'en': '', 'ar': ''}),
      offerPrice: (map['offerPrice'] as num?)?.toDouble() ?? 0.0,
      authenticity: map['authenticity'] ?? 'Original',
      fulfillmentType: map['fulfillmentType'] ?? 'Store Pickup',
      status: map['status'] ?? 'pending',
      businessTrustScore: (map['businessTrustScore'] as num?)?.toDouble() ?? 50.0,
      adminNotes: Map<String, String>.from(map['adminNotes'] ?? {'en': '', 'ar': ''}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      minCommitments: (map['minCommitments'] as num?)?.toInt() ?? 20, // 🆕
      commitCount: (map['commitCount'] as num?)?.toInt() ?? 0, // 🆕
    );
  }
}