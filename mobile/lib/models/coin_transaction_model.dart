import 'package:cloud_firestore/cloud_firestore.dart';

/// A single MIGO Coins transaction（Firestore: coin_transactions/{id}）.
class CoinTransactionModel {
  const CoinTransactionModel({
    required this.id,
    required this.uid,
    required this.amount,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String uid;
  final int amount; // positive = earned, negative = spent
  final String reason;
  final DateTime createdAt;

  bool get isEarned => amount >= 0;

  factory CoinTransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return CoinTransactionModel(
      id: id,
      uid: (map['uid'] ?? '') as String,
      amount: (map['amount'] as num? ?? 0).toInt(),
      reason: (map['reason'] ?? '') as String,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}