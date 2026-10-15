import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// PHASE E — E10: Anti-Fraud Basic
/// Simple fraud detection for claims, referrals, coins
class FraudService {
  FraudService._();
  static final FraudService instance = FraudService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ═══════════════════════════════════════════════════
  /// 1. SELF-REFERRAL CHECK
  /// ═══════════════════════════════════════════════════
  /// User cannot refer themselves
  Future<bool> isSelfReferral({
    required String referrerUid,
    required String referredUid,
  }) async {
    return referrerUid == referredUid;
  }

  /// ═══════════════════════════════════════════════════
  /// 2. DUPLICATE CLAIM CHECK
  /// ═══════════════════════════════════════════════════
  /// Same user cannot claim same offer twice
  Future<bool> hasAlreadyClaimed({
    required String userUid,
    required String offerId,
  }) async {
    try {
      final snap = await _db
          .collection('claims')
          .where('userUid', isEqualTo: userUid)
          .where('offerId', isEqualTo: offerId)
          .limit(1)
          .get();

      return snap.docs.isNotEmpty;
    } catch (_) {
      // Query fails → allow (fail open, don't block user)
      return false;
    }
  }

  /// ═══════════════════════════════════════════════════
  /// 3. RAPID CLAIM DETECTION
  /// ═══════════════════════════════════════════════════
  /// Check if user made too many claims in short time
  Future<bool> isRapidClaiming({
    required String userUid,
    Duration window = const Duration(minutes: 5),
    int maxClaims = 10,
  }) async {
    try {
      final cutoff = DateTime.now().subtract(window);

      final snap = await _db
          .collection('claims')
          .where('userUid', isEqualTo: userUid)
          .where('createdAt',
              isGreaterThan: Timestamp.fromDate(cutoff))
          .get();

      return snap.docs.length >= maxClaims;
    } catch (_) {
      return false;
    }
  }

  /// ═══════════════════════════════════════════════════
  /// 4. RAPID REFERRAL DETECTION
  /// ═══════════════════════════════════════════════════
  /// Check if user referred too many people quickly
  Future<bool> isRapidReferring({
    required String referrerUid,
    Duration window = const Duration(hours: 1),
    int maxReferrals = 20,
  }) async {
    try {
      final cutoff = DateTime.now().subtract(window);

      final snap = await _db
          .collection('referrals')
          .where('referrerUid', isEqualTo: referrerUid)
          .where('createdAt',
              isGreaterThan: Timestamp.fromDate(cutoff))
          .get();

      return snap.docs.length >= maxReferrals;
    } catch (_) {
      return false;
    }
  }

  /// ═══════════════════════════════════════════════════
  /// 5. COIN FARMING DETECTION
  /// ═══════════════════════════════════════════════════
  /// Check coin transactions for suspicious patterns
  Future<bool> isCoinFarming({
    required String userUid,
    Duration window = const Duration(minutes: 10),
    int maxTransactions = 15,
  }) async {
    try {
      final cutoff = DateTime.now().subtract(window);

      final snap = await _db
          .collection('coin_transactions')
          .where('uid', isEqualTo: userUid)
          .where('createdAt',
              isGreaterThan: Timestamp.fromDate(cutoff))
          .get();

      return snap.docs.length >= maxTransactions;
    } catch (_) {
      return false;
    }
  }

  /// ═══════════════════════════════════════════════════
  /// 6. LOG SUSPICIOUS ACTIVITY
  /// ═══════════════════════════════════════════════════
  /// Records suspected fraud for admin review
  Future<void> logSuspicious({
    required String userUid,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _db.collection('fraud_logs').add({
        'userUid': userUid,
        'reason': reason,
        'metadata': metadata ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'reviewed': false,
      });
    } catch (_) {
      // Silent fail — don't disrupt user flow
    }
  }

  /// ═══════════════════════════════════════════════════
  /// 7. COMBINED CLAIM CHECK
  /// ═══════════════════════════════════════════════════
  /// Runs all pre-claim validations
  /// Returns null if OK, error message if blocked
  Future<String?> validateClaim({
    required String offerId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Not signed in';

    // 1. Duplicate check
    final duplicate = await hasAlreadyClaimed(
      userUid: uid,
      offerId: offerId,
    );
    if (duplicate) {
      await logSuspicious(
        userUid: uid,
        reason: 'duplicate_claim',
        metadata: {'offerId': offerId},
      );
      return 'You already claimed this offer';
    }

    // 2. Rapid claim check
    final rapid = await isRapidClaiming(userUid: uid);
    if (rapid) {
      await logSuspicious(
        userUid: uid,
        reason: 'rapid_claiming',
        metadata: {'offerId': offerId},
      );
      return 'Too many claims. Please wait a moment.';
    }

    return null; // ✅ All good
  }

  /// ═══════════════════════════════════════════════════
  /// 8. COMBINED REFERRAL CHECK
  /// ═══════════════════════════════════════════════════
  Future<String?> validateReferral({
    required String referrerUid,
    required String referredUid,
  }) async {
    // 1. Self-referral
    if (await isSelfReferral(
      referrerUid: referrerUid,
      referredUid: referredUid,
    )) {
      await logSuspicious(
        userUid: referredUid,
        reason: 'self_referral',
        metadata: {'referrerUid': referrerUid},
      );
      return 'Cannot refer yourself';
    }

    // 2. Rapid referring
    if (await isRapidReferring(referrerUid: referrerUid)) {
      await logSuspicious(
        userUid: referrerUid,
        reason: 'rapid_referring',
        metadata: {'referredUid': referredUid},
      );
      return 'Too many referrals. Please slow down.';
    }

    return null; // ✅ All good
  }
}