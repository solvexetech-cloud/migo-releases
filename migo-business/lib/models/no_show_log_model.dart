// ═══════════════════════════════════════════════════════
// MIGO — No-Show Log Model (PHASE H)
// ═══════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';

class NoShowLogModel {
  final String id;
  final String userUid;
  final String userName;
  final String businessId;
  final String businessName;
  final String offerId;
  final String reservationId;
  final String reason;
  final DateTime timestamp;
  final DateTime? createdAt;

  NoShowLogModel({
    required this.id,
    required this.userUid,
    required this.userName,
    required this.businessId,
    required this.businessName,
    required this.offerId,
    required this.reservationId,
    required this.reason,
    required this.timestamp,
    this.createdAt,
  });

  bool get isExpired => reason == 'expired';
  bool get isManual => reason == 'manual';

  factory NoShowLogModel.fromMap(String id, Map<String, dynamic> data) {
    return NoShowLogModel(
      id: id,
      userUid: data['userUid'] ?? '',
      userName: data['userName'] ?? '',
      businessId: data['businessId'] ?? '',
      businessName: data['businessName'] ?? '',
      offerId: data['offerId'] ?? '',
      reservationId: data['reservationId'] ?? '',
      reason: data['reason'] ?? 'expired',
      timestamp:
          (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userUid': userUid,
      'userName': userName,
      'businessId': businessId,
      'businessName': businessName,
      'offerId': offerId,
      'reservationId': reservationId,
      'reason': reason,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt':
          createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}