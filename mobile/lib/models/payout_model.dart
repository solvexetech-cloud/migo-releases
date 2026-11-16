import 'package:cloud_firestore/cloud_firestore.dart';

class PayoutModel {
  final String id;
  final String creatorId;
  final double amount;
  final String status; // 'requested', 'approved', 'completed', 'rejected'
  final DateTime requestedAt;
  final String? transactionId;

  PayoutModel({
    required this.id,
    required this.creatorId,
    required this.amount,
    required this.status,
    required this.requestedAt,
    this.transactionId,
  });

  factory PayoutModel.fromMap(String id, Map<String, dynamic> data) {
    return PayoutModel(
      id: id,
      creatorId: data['creatorId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      status: data['status'] ?? 'requested',
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      transactionId: data['transactionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'amount': amount,
      'status': status,
      'requestedAt': FieldValue.serverTimestamp(),
      'transactionId': transactionId,
    };
  }
}