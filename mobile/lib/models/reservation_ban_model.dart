// ═══════════════════════════════════════════════════════
// MIGO — Reservation Ban Model (PHASE H)
// ═══════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationBanModel {
  final String userUid; // Document ID = userUid
  final DateTime bannedUntil;
  final String reason;
  final int noShowCount;
  final String createdBy; // 'system' or admin uid
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReservationBanModel({
    required this.userUid,
    required this.bannedUntil,
    required this.reason,
    required this.noShowCount,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  // ─────────────────────────────────────────────────────
  // Computed
  // ─────────────────────────────────────────────────────
  bool get isActive => bannedUntil.isAfter(DateTime.now());

  Duration get remaining => bannedUntil.difference(DateTime.now());

  int get remainingDays {
    final d = remaining.inDays;
    return d < 0 ? 0 : d;
  }

  // ─────────────────────────────────────────────────────
  // From Firestore
  // ─────────────────────────────────────────────────────
  factory ReservationBanModel.fromMap(
      String userUid, Map<String, dynamic> data) {
    return ReservationBanModel(
      userUid: userUid,
      bannedUntil: (data['bannedUntil'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      reason: data['reason'] ?? 'No-show violation',
      noShowCount: (data['noShowCount'] as num?)?.toInt() ?? 0,
      createdBy: data['createdBy'] ?? 'system',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // ─────────────────────────────────────────────────────
  // To Firestore
  // ─────────────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'userUid': userUid,
      'bannedUntil': Timestamp.fromDate(bannedUntil),
      'reason': reason,
      'noShowCount': noShowCount,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}