import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/claim_model.dart';

class ClaimService {
  ClaimService._();
  static final ClaimService instance = ClaimService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _claims => _db.collection('claims');
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _notifications => _db.collection('notifications');

  Future<void> redeemClaim({
    required String claimId,
    required String businessId,
  }) async {
    debugPrint('ðŸ”µ redeemClaim: claimId=$claimId');

    // âœ… 1. QR à´•àµ‹à´¡àµ à´‰à´ªà´¯àµ‹à´—à´¿à´šàµà´šàµ 'demand_claims' à´•à´³à´•àµà´·à´¨à´¿àµ½ à´¤à´¿à´°à´¯àµà´¨àµà´¨àµ
    var querySnapshot = await _db.collection('demand_claims')
        .where('qrData', isEqualTo: claimId)
        .limit(1)
        .get();

    // âœ… 2. à´’à´°àµ à´ªà´•àµà´·àµ‡ QR à´¡à´¾à´±àµà´± à´•à´£àµà´Ÿàµ†à´¤àµà´¤à´¿à´¯à´¿à´²àµà´²àµ†à´™àµà´•à´¿àµ½, redemptionPin à´‰à´ªà´¯àµ‹à´—à´¿à´šàµà´šàµ à´¨àµ‹à´•àµà´•àµà´¨àµà´¨àµ
    if (querySnapshot.docs.isEmpty) {
       querySnapshot = await _db.collection('demand_claims')
        .where('redemptionPin', isEqualTo: claimId)
        .limit(1)
        .get();
    }

    // âœ… 3. à´…à´¤àµà´‚ à´•à´£àµà´Ÿàµ†à´¤àµà´¤à´¿à´¯à´¿à´²àµà´²àµ†à´™àµà´•à´¿àµ½, à´¨àµ‡à´°à´¿à´Ÿàµà´Ÿàµ à´¡àµ‹à´•àµà´¯àµà´®àµ†à´¨àµà´±àµ ID à´†à´¯à´¿ à´¤à´¿à´°à´¯àµà´¨àµà´¨àµ
    if (querySnapshot.docs.isEmpty) {
       querySnapshot = await _db.collection('demand_claims')
        .where(FieldPath.documentId, isEqualTo: claimId)
        .limit(1)
        .get();
    }

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Invalid or already used QR code');
    }

    final snap = querySnapshot.docs.first;
    final data = snap.data() as Map<String, dynamic>;
    
    if (data['status'] != 'locked') {
       throw Exception('This claim is already ${data['status']}.');
    }

    // 4. Mark as redeemed (à´‡à´µà´¿à´Ÿàµ† à´±àµ‚à´³àµà´®à´¾à´¯à´¿ à´ªàµŠà´°àµà´¤àµà´¤à´ªàµà´ªàµ†à´Ÿà´¾àµ» businessId à´¨àµ½à´•àµà´¨àµà´¨àµ)
    await _db.collection('demand_claims').doc(snap.id).update({
      'status': 'redeemed',
      'redeemedAt': FieldValue.serverTimestamp(),
      'businessId': FirebaseAuth.instance.currentUser?.uid, // âœ… à´²àµ‹à´—à´¿àµ» UID
      'redeemedBy': FirebaseAuth.instance.currentUser?.uid,
    });

    debugPrint('âœ… Claim redeemed successfully!');
  }

  // ðŸ†• Coin Payment Accept (Pay with Coins)
  Future<void> acceptCoinPayment({
    required String paymentId,
    required String customerUid,
    required int coinsUsed,
    required String businessId,
  }) async {
    final ref = _db.collection('coin_payments').doc(paymentId);
    
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception("Payment request not found");
      if (snap.data()!['status'] != 'pending') throw Exception("Already processed");

      tx.update(ref, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      final userRef = _users.doc(customerUid);
      tx.update(userRef, {
        'coins': FieldValue.increment(-coinsUsed),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final txRef = _db.collection('coin_transactions').doc();
      tx.set(txRef, {
        'uid': customerUid,
        'amount': -coinsUsed,
        'type': 'spent',
        'description': 'Paid at business ($businessId)',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> _addCoins({
    required String uid,
    required int amount,
    required String reason,
    required int expiryDays,
  }) async {
    try {
      final expiryDate = DateTime.now().add(Duration(days: expiryDays));

      await _users.doc(uid).update({
        'coins': FieldValue.increment(amount),
        'coinsExpireAt': Timestamp.fromDate(expiryDate),
      });

      await _db.collection('coin_transactions').add({
        'uid': uid,
        'amount': amount,
        'type': 'redeem',
        'description': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('âš ï¸ addCoins error: $e');
    }
  }
}