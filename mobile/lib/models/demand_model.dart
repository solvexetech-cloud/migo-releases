import 'package:cloud_firestore/cloud_firestore.dart';

class DemandModel {
  final String id;
  final String userId;
  final String userName;
  final Map<String, String> title; // {'en': '...', 'ar': '...'}
  final Map<String, String> description;
  final double targetPrice;
  final String currency;
  final int requiredCount;
  final int currentCount;
  final String status; // 'open', 'threshold_reached', 'locked', 'expired'
  final DateTime createdAt;
  final DateTime expiresAt;
  final String areaId;

  DemandModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.description,
    required this.targetPrice,
    required this.currency,
    required this.requiredCount,
    required this.currentCount,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.areaId,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'title': title,
      'description': description,
      'targetPrice': targetPrice,
      'currency': currency,
      'requiredCount': requiredCount,
      'currentCount': currentCount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'areaId': areaId,
    };
  }

  factory DemandModel.fromMap(String id, Map<String, dynamic> map) {
    return DemandModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      title: Map<String, String>.from(map['title'] ?? {'en': '', 'ar': ''}),
      description: Map<String, String>.from(map['description'] ?? {'en': '', 'ar': ''}),
      targetPrice: (map['targetPrice'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'QAR',
      requiredCount: (map['requiredCount'] as num?)?.toInt() ?? 1,
      currentCount: (map['currentCount'] as num?)?.toInt() ?? 0,
      status: map['status'] ?? 'open',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 3)),
      areaId: map['areaId'] ?? '',
    );
  }
}
