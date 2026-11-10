// mobile/lib/models/demand_group_model.dart
// UPDATED FILE - Added deliveryDate
import 'package:cloud_firestore/cloud_firestore.dart';

class DemandGroupModel {
  final String id;
  final String title;
  final String category;
  final String zoneId;
  final String countryCode;
  final int memberCount;
  final List<String> members;
  final List<String> memberDemandIds;
  final int threshold;
  final String status;
  final int totalQuantity;
  final double minTargetPrice;
  final double maxTargetPrice;
  final double avgTargetPrice;
  final DateTime createdAt;
  final DateTime? thresholdReachedAt;
  final DateTime? expiresAt;
  final DateTime? updatedAt;
  final DateTime? deliveryDate;

  DemandGroupModel({
    required this.id,
    required this.title,
    required this.category,
    required this.zoneId,
    required this.countryCode,
    required this.memberCount,
    required this.members,
    required this.memberDemandIds,
    required this.threshold,
    required this.status,
    required this.totalQuantity,
    required this.minTargetPrice,
    required this.maxTargetPrice,
    required this.avgTargetPrice,
    required this.createdAt,
    this.thresholdReachedAt,
    this.expiresAt,
    this.updatedAt,
    this.deliveryDate,
  });

  factory DemandGroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DemandGroupModel(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      zoneId: data['zoneId'] ?? '',
      countryCode: data['countryCode'] ?? '',
      memberCount: data['memberCount'] ?? 0,
      members: List<String>.from(data['members'] ?? []),
      memberDemandIds: List<String>.from(data['memberDemandIds'] ?? []),
      threshold: data['threshold'] ?? 3,
      status: data['status'] ?? 'collecting',
      totalQuantity: data['totalQuantity'] ?? 0,
      minTargetPrice: (data['minTargetPrice'] ?? 0).toDouble(),
      maxTargetPrice: (data['maxTargetPrice'] ?? 0).toDouble(),
      avgTargetPrice: (data['avgTargetPrice'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      thresholdReachedAt: (data['thresholdReachedAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      deliveryDate: (data['deliveryDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'zoneId': zoneId,
      'countryCode': countryCode,
      'memberCount': memberCount,
      'members': members,
      'memberDemandIds': memberDemandIds,
      'threshold': threshold,
      'status': status,
      'totalQuantity': totalQuantity,
      'minTargetPrice': minTargetPrice,
      'maxTargetPrice': maxTargetPrice,
      'avgTargetPrice': avgTargetPrice,
      'createdAt': Timestamp.fromDate(createdAt),
      'thresholdReachedAt': thresholdReachedAt != null ? Timestamp.fromDate(thresholdReachedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : Timestamp.fromDate(DateTime.now()),
      'deliveryDate': deliveryDate != null ? Timestamp.fromDate(deliveryDate!) : null,
    };
  }
}