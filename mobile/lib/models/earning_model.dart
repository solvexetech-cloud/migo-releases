import 'package:cloud_firestore/cloud_firestore.dart';

class EarningModel {
  final String id;
  final String creatorId;
  final String claimId;
  final double amount;
  final String currency;
  final String status; // pending, approved, paid, reversed
  final DateTime createdAt;
  final DateTime? approvedAt;

  EarningModel({
    required this.id,
    required this.creatorId,
    required this.claimId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.approvedAt,
  });

  factory EarningModel.fromMap(String id, Map<String, dynamic> map) {
    return EarningModel(
      id: id,
      creatorId: map['creatorId'] ?? '',
      claimId: map['claimId'] ?? '',
      amount: (map['amount'] as num? ?? 0).toDouble(),
      currency: map['currency'] ?? 'QAR',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'claimId': claimId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    };
  }
}