import 'package:cloud_firestore/cloud_firestore.dart';
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
    debugPrint('🔵 redeemClaim: claimId=$claimId');

    // 1. നൽകിയ കോഡ് ഉപയോഗിച്ച് 'claimId' ഫീൽഡിൽ തിരയുന്നു
    final querySnapshot = await _claims
        .where('claimId', isEqualTo: claimId)
        .limit(1)
        .get();
    
    // 2. കിട്ടിയില്ലെങ്കിൽ, നേരിട്ട് ഡോക്യുമെന്റ് ID ആയി തിരയുന്നു
    final snap = querySnapshot.docs.isEmpty 
        ? await _claims.doc(claimId).get() 
        : await _claims.doc(querySnapshot.docs.first.id).get();

    if (!snap.exists || snap.data() == null) {
      throw Exception('Claim not found');
    }

    final claim = ClaimModel.fromMap(
      snap.id, // യഥാർത്ഥ ഡോക്യുമെന്റ് ID ഉപയോഗിക്കുന്നു
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

    // 3. Mark as redeemed
    await _claims.doc(snap.id).update({
      'status': ClaimStatus.redeemed.id,
      'redeemedAt': FieldValue.serverTimestamp(),
      'redeemedBy': businessId,
    });

    // 4. Add coins to customer
    final configSnap = await _db.collection('config').doc('coin_settings').get();
    final config = configSnap.data();
    final int claimReward = (config?['rewards']?['claim'] as num?)?.toInt() ?? 10;
    final int expiryDays = (config?['expiryDays'] as num?)?.toInt() ?? 60;

    await _addCoins(
      uid: claim.userUid,
      amount: claimReward,
      reason: 'Redeemed "${claim.offerTitle}"',
      expiryDays: expiryDays,
    );

    // 5. Notification
    await _notifications.add({
      'userUid': claim.userUid,
      'type': 'coinEarned',
      'title': '+$claimReward MIGO Coins',
      'body': 'Your "${claim.offerTitle}" was redeemed at ${claim.businessName}.',
      'targetRoute': 'wallet',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Claim redeemed');
  }

  // 🆕 Coin Payment Accept (Pay with Coins)
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

      // 1. പേയ്‌മെന്റ് സ്റ്റാറ്റസ് അപ്ഡേറ്റ് ചെയ്യുന്നു
      tx.update(ref, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // 2. കസ്റ്റമറുടെ കോയിൻസ് കുറയ്ക്കുന്നു
      final userRef = _users.doc(customerUid);
      tx.update(userRef, {
        'coins': FieldValue.increment(-coinsUsed),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. കോയിൻ ട്രാൻസാക്ഷൻ ലോഗ് ചെയ്യുന്നു
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
      debugPrint('⚠️ addCoins error: $e');
    }
  }
}