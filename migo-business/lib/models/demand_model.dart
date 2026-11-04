import 'package:cloud_firestore/cloud_firestore.dart';

class DemandModel {
  final String id;
  final String userId;
  final String userName;
  final Map<String, String> title;
  final Map<String, String> description;
  final double targetPrice;
  final String currency;
  final int minRequiredCount;
  final int currentCount;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String areaId;
  final String category;
  final bool isPrivate;
  final int quantity;
  final DateTime? deliveryDate;

  DemandModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.description,
    required this.targetPrice,
    required this.currency,
    required this.minRequiredCount,
    required this.currentCount,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.areaId,
    required this.category,
    required this.isPrivate,
    required this.quantity,
    this.deliveryDate,
  });

  // 🆕 പഴയ കോഡുകൾ കേടാകാതിരിക്കാൻ
  int get requiredCount => minRequiredCount; 

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'title': title,
      'description': description,
      'targetPrice': targetPrice,
      'currency': currency,
      'minRequiredCount': minRequiredCount,
      'currentCount': currentCount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'areaId': areaId,
      'category': category,
      'isPrivate': isPrivate,
      'quantity': quantity,
      'deliveryDate': deliveryDate != null ? Timestamp.fromDate(deliveryDate!) : null,
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
      minRequiredCount: (map['minRequiredCount'] as num?)?.toInt() ?? 15,
      currentCount: (map['currentCount'] as num?)?.toInt() ?? 1,
      status: map['status'] ?? 'open',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      areaId: map['areaId'] ?? '',
      category: map['category'] ?? 'General',
      isPrivate: map['isPrivate'] ?? false,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      deliveryDate: (map['deliveryDate'] as Timestamp?)?.toDate(),
    );
  }
}