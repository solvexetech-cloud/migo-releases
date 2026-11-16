import 'package:cloud_firestore/cloud_firestore.dart';

class EarningModel {
  final String id;
  final String creatorId;
  final String shopId;
  final String collabId;
  final double amount;
  final String status; // 'pending', 'approved', 'paid'
  final DateTime createdAt;

  EarningModel({
    required this.id,
    required this.creatorId,
    required this.shopId,
    required this.collabId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory EarningModel.fromMap(String id, Map<String, dynamic> data) {
    return EarningModel(
      id: id,
      creatorId: data['creatorId'] ?? '',
      shopId: data['shopId'] ?? '',
      collabId: data['collabId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'shopId': shopId,
      'collabId': collabId,
      'amount': amount,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}