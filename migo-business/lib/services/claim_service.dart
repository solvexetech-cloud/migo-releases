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
    await _addCoins(
      uid: claim.userUid,
      amount: 25,
      reason: 'Redeemed "${claim.offerTitle}"',
    );

    // 5. Notification
    await _notifications.add({
      'userUid': claim.userUid,
      'type': 'coinEarned',
      'title': '+25 MIGO Coins',
      'body': 'Your "${claim.offerTitle}" was redeemed at ${claim.businessName}.',
      'targetRoute': 'wallet',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Claim redeemed');
  }

  Future<void> _addCoins({
    required String uid,
    required int amount,
    required String reason,
  }) async {
    try {
      // Users കളക്ഷനിൽ 'coins' മാത്രം അപ്ഡേറ്റ് ചെയ്യുന്നു (updatedAt ഇല്ല)
      await _users.doc(uid).update({
        'coins': FieldValue.increment(amount),
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