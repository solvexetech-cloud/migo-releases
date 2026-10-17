import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'fraud_service.dart';

/// MIGO Coin Service
/// Handles earning and spending coins (Client-Side)
class CoinService {
  CoinService._();
  static final CoinService instance = CoinService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Coin Values Definition ---
  static const int dailyBonus = 2;
  static const int claimDeal = 5;
  static const int redeemAtBusiness = 25;
  static const int writeReview = 10;
  static const int referFriend = 50;
  static const int firstClaimBonus = 50; // Extra bonus

  /// Grant coins to the current user
  Future<bool> earnCoins({
    required int amount,
    required String reason,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      // 1. Fraud Check
      final isFarming = await FraudService.instance.isCoinFarming(userUid: uid);
      if (isFarming) {
        await FraudService.instance.logSuspicious(
          userUid: uid,
          reason: 'coin_farming_attempt',
          metadata: {'reason': reason, 'amount': amount},
        );
        return false;
      }

      // 2. Add Transaction & Update Balance (Batch Write)
      final batch = _db.batch();

      // Create transaction log
      final txRef = _db.collection('coin_transactions').doc();
      batch.set(txRef, {
        'uid': uid,
        'amount': amount,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update user balance
      final userRef = _db.collection('users').doc(uid);
      batch.update(userRef, {
        'coins': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error earning coins: $e');
      return false;
    }
  }

  /// Deduct coins from the current user
  Future<bool> spendCoins({
    required int amount,
    required String reason,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      // 1. Check Balance
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) return false;
      
      final user = UserModel.fromMap(uid, userDoc.data()!);
      if (user.coins < amount) return false; // Not enough coins

      // 2. Deduct Coins
      final batch = _db.batch();

      // Create transaction log (negative amount)
      final txRef = _db.collection('coin_transactions').doc();
      batch.set(txRef, {
        'uid': uid,
        'amount': -amount, // Negative for spend
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update user balance
      final userRef = _db.collection('users').doc(uid);
      batch.update(userRef, {
        'coins': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error spending coins: $e');
      return false;
    }
  }

  /// Check if user has enough coins
  Future<bool> hasEnoughCoins(int amount) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    
    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) return false;
    
    final user = UserModel.fromMap(uid, userDoc.data()!);
    return user.coins >= amount;
  }
}