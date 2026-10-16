import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/claim_model.dart';

/// PHASE I — Claim Service (redeem QR code)
class ClaimService {
  ClaimService._();
  static final ClaimService instance = ClaimService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _claims => _db.collection('claims');
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _notifications =>
      _db.collection('notifications');

  // ═══════════════════════════════════════════════════
  // REDEEM CLAIM
  // ═══════════════════════════════════════════════════
  Future<void> redeemClaim({
    required String claimId,
    required String businessId,
  }) async {
    debugPrint('🔵 redeemClaim: claimId=$claimId');

    final snap = await _claims.doc(claimId).get();
    if (!snap.exists || snap.data() == null) {
      throw Exception('Claim not found');
    }

    final claim = ClaimModel.fromMap(
      claimId,
      snap.data()! as Map<String, dynamic>,
    );

    if (claim.businessId != businessId) {
      throw Exception('This claim belongs to a different business.');
    }
    if (claim.status != ClaimStatus.active) {
      throw Exception(
        'Claim is already ${claim.status.label.toLowerCase()}.',
      );
    }
    if (claim.expiresAt.isBefore(DateTime.now())) {
      throw Exception('This claim has expired.');
    }

    // Mark as redeemed
    await _claims.doc(claimId).update({
      'status': ClaimStatus.redeemed.id,
      'redeemedAt': FieldValue.serverTimestamp(),
      'redeemedBy': businessId,
    });

    // Add coins to customer
    await _addCoins(
      uid: claim.userUid,
      amount: 25,
      reason: 'Redeemed "${claim.offerTitle}"',
    );

    // Notification
    await _notifications.add({
      'userUid': claim.userUid,
      'type': 'coinEarned',
      'title': '+25 MIGO Coins',
      'body':
          'Your "${claim.offerTitle}" was redeemed at ${claim.businessName}.',
      'targetRoute': 'wallet',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Claim redeemed');
  }

  // ═══════════════════════════════════════════════════
  // ADD COINS
  // ═══════════════════════════════════════════════════
  Future<void> _addCoins({
    required String uid,
    required int amount,
    required String reason,
  }) async {
    try {
      await _users.doc(uid).update({
        'coins': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('coin_transactions').add({
        'uid': uid,
        'amount': amount,
        'type': 'redeem',
        'description': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ addCoins error: $e');
    }
  }
}