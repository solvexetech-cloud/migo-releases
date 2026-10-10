// ═══════════════════════════════════════════════════════
// MIGO — Reservation Service (PHASE H)
// ═══════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/reservation_model.dart';
import '../models/reservation_rules_model.dart';
import '../models/reservation_config_model.dart';
import '../models/reservation_ban_model.dart';

class ReservationService {
  ReservationService._();
  static final ReservationService instance = ReservationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─────────────────────────────────────────────────────
  // Collection refs
  // ─────────────────────────────────────────────────────
  CollectionReference get _reservations =>
      _db.collection('reservations');
  CollectionReference get _rules =>
      _db.collection('reservation_rules');
  CollectionReference get _config =>
      _db.collection('reservation_config');
  CollectionReference get _noShowLog =>
      _db.collection('no_show_log');
  CollectionReference get _bans =>
      _db.collection('reservation_bans');
  CollectionReference get _acceptance =>
      _db.collection('reservation_rules_acceptance');
  CollectionReference get _offers => _db.collection('offers');
  CollectionReference get _users => _db.collection('users');

  // ─────────────────────────────────────────────────────
  // Cache
  // ─────────────────────────────────────────────────────
  ReservationConfigModel? _cachedConfig;
  ReservationRulesModel? _cachedRules;
  DateTime? _configCacheTime;
  DateTime? _rulesCacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // ═══════════════════════════════════════════════════════
  // CONFIG
  // ═══════════════════════════════════════════════════════
  Future<ReservationConfigModel> getConfig({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh &&
          _cachedConfig != null &&
          _configCacheTime != null &&
          DateTime.now().difference(_configCacheTime!) < _cacheDuration) {
        return _cachedConfig!;
      }

      final doc = await _config.doc('global').get();
      if (!doc.exists) {
        _cachedConfig = ReservationConfigModel.defaults();
      } else {
        _cachedConfig = ReservationConfigModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }
      _configCacheTime = DateTime.now();
      return _cachedConfig!;
    } catch (e) {
      debugPrint('⚠️ getConfig error: $e');
      return ReservationConfigModel.defaults();
    }
  }

  // ═══════════════════════════════════════════════════════
  // RULES
  // ═══════════════════════════════════════════════════════
  Future<ReservationRulesModel?> getActiveRules({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh &&
          _cachedRules != null &&
          _rulesCacheTime != null &&
          DateTime.now().difference(_rulesCacheTime!) < _cacheDuration) {
        return _cachedRules;
      }

      final snap = await _rules
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        debugPrint('⚠️ No active rules found');
        return null;
      }

      final doc = snap.docs.first;
      _cachedRules = ReservationRulesModel.fromMap(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );
      _rulesCacheTime = DateTime.now();
      return _cachedRules;
    } catch (e) {
      debugPrint('⚠️ getActiveRules error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════
  // RULES ACCEPTANCE
  // ═══════════════════════════════════════════════════════
  Future<bool> hasAcceptedRules(String uid, String version) async {
    try {
      final docId = '${uid}_$version';
      final doc = await _acceptance.doc(docId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('⚠️ hasAcceptedRules error: $e');
      return false;
    }
  }

  Future<void> acceptRules(String uid, String version) async {
    try {
      final docId = '${uid}_$version';
      await _acceptance.doc(docId).set({
        'userUid': uid,
        'version': version,
        'acceptedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ acceptRules error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════
  // BAN CHECK
  // ═══════════════════════════════════════════════════════
  Future<ReservationBanModel?> checkBan(String uid) async {
    try {
      final doc = await _bans.doc(uid).get();
      if (!doc.exists) return null;
      final ban = ReservationBanModel.fromMap(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );
      return ban.isActive ? ban : null;
    } catch (e) {
      debugPrint('⚠️ checkBan error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════
  // CAN BOOK CHECK
  // ═══════════════════════════════════════════════════════
  Future<CanBookResult> checkCanBook({
    required String uid,
    required String offerId,
  }) async {
    try {
      // 1. Config
      final config = await getConfig();
      if (!config.enabled) {
        return CanBookResult(
          canBook: false,
          reason: 'Reserve feature is currently disabled',
        );
      }

      // 2. Ban
      final ban = await checkBan(uid);
      if (ban != null) {
        return CanBookResult(
          canBook: false,
          reason:
              'You are temporarily banned until ${ban.bannedUntil.toString().split('.')[0]}',
        );
      }

            // 3. Rules
      final rules = await getActiveRules();
      if (rules == null) {
        return CanBookResult(
          canBook: false,
          reason: 'No active rules found. Contact support.',
        );
      }

      final accepted = await hasAcceptedRules(uid, rules.version);
      if (!accepted) {
        return CanBookResult(
          canBook: false,
          reason: 'Please accept the Reserve Rules first',
          needsRulesAcceptance: true,
          rulesVersion: rules.version,
        );
      }

      // 4. Offer slots
      final offerDoc = await _offers.doc(offerId).get();
      if (!offerDoc.exists) {
        return CanBookResult(
          canBook: false,
          reason: 'Offer not found',
        );
      }

      final offerData = offerDoc.data() as Map<String, dynamic>;
      final totalSlots = (offerData['totalSlots'] as num?)?.toInt() ?? 0;
      final bookedSlots = (offerData['bookedSlots'] as num?)?.toInt() ?? 0;
      final remaining = totalSlots - bookedSlots;

      if (remaining <= 0) {
        return CanBookResult(
          canBook: false,
          reason: 'Sold out',
          remainingSlots: 0,
        );
      }

      // 5. Location lock
      if (config.locationLockEnabled) {
        final userDoc = await _users.doc(uid).get();
        if (!userDoc.exists) {
          return CanBookResult(
            canBook: false,
            reason: 'User profile not found',
          );
        }
        final userData = userDoc.data() as Map<String, dynamic>;
        final userArea = userData['currentAreaId'] as String?;
        final offerArea = offerData['areaId'] as String?;
        if (userArea != null && offerArea != null && userArea != offerArea) {
          return CanBookResult(
            canBook: false,
            reason: 'Reservations only for your current area',
          );
        }
      }

      return CanBookResult(
        canBook: true,
        remainingSlots: remaining,
        config: config,
        rules: rules,
      );
    } catch (e) {
      debugPrint('❌ checkCanBook error: $e');
      return CanBookResult(
        canBook: false,
        reason: 'Error checking: $e',
      );
    }
  }

  // ═══════════════════════════════════════════════════════
  // CREATE RESERVATION (Transaction)
  // ═══════════════════════════════════════════════════════
  Future<String> createReservation({
    required String uid,
    required String offerId,
    required int quantity,
    String? notes,
  }) async {
    // 1. Re-validate before transaction
    final canBook = await checkCanBook(uid: uid, offerId: offerId);
    if (!canBook.canBook) {
      throw Exception(canBook.reason ?? 'Cannot book now');
    }
    if (canBook.remainingSlots != null &&
        quantity > canBook.remainingSlots!) {
      throw Exception('Only ${canBook.remainingSlots} slots left');
    }

    // 2. Get user + offer data (for denormalization)
    final userDoc = await _users.doc(uid).get();
    if (!userDoc.exists) {
      throw Exception('User not found');
    }
    final userData = userDoc.data() as Map<String, dynamic>;

    final config = canBook.config ?? await getConfig();
 
    // 3. Generate unique codes
    final qrCode = _generateUUID();
    final pickupCode = _generate6DigitCode();
    final now = DateTime.now();
    final expiresAt = now.add(Duration(hours: config.defaultHoldHours));

    // 4. Generate reservation doc ref
    final reservationRef = _reservations.doc();

    // 5. Run transaction
    await _db.runTransaction((transaction) async {
      // Re-read offer fresh
      final offerRef = _offers.doc(offerId);
      final offerSnap = await transaction.get(offerRef);

      if (!offerSnap.exists) {
        throw Exception('Offer not found');
      }

      final offerData = offerSnap.data() as Map<String, dynamic>;
      final totalSlots = (offerData['totalSlots'] as num?)?.toInt() ?? 0;
      final bookedSlots = (offerData['bookedSlots'] as num?)?.toInt() ?? 0;
      final remaining = totalSlots - bookedSlots;

      if (remaining < quantity) {
        throw Exception('Not enough slots (only $remaining left)');
      }

      // Build reservation data
      final reservationData = {
        // Core
        'userUid': uid,
        'userName': userData['displayName'] ?? '',
        'userPhone': userData['phone'] ?? '',

        // Business (denormalized from offer)
        'businessId': offerData['businessId'] ?? '',
        'businessName': offerData['businessName'] ?? '',
        'businessPhone': offerData['businessPhone'] ?? '',

        // Offer (denormalized)
        'offerId': offerId,
        'offerTitle': offerData['title'] ?? '',
        'offerImageUrl': offerData['imageUrl'] ?? '',

        // Quantity & pricing
        'quantity': quantity,
        'unitPrice': (offerData['price'] as num?)?.toDouble() ?? 0,
        'originalPrice': (offerData['originalPrice'] as num?)?.toDouble() ?? 0,
        'currency': offerData['currency'] ?? 'QAR',
        'totalAmount':
            ((offerData['price'] as num?)?.toDouble() ?? 0) * quantity,

        // Timing
        'bookedAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'pickedUpAt': null,
        'cancelledAt': null,
        'cancelledBy': null,

        // Status
        'status': 'reserved',

        // Pickup
        'pickupCode': pickupCode,
        'qrCode': qrCode,

        // Token
        'tokenRequired': config.tokenRequired,
        'tokenAmount': config.tokenRequired ? config.tokenAmount : 0,
        'tokenPaymentId': null,
        'tokenRefunded': false,
        'tokenForfeited': false,

        // Location
        'areaId': offerData['areaId'] ?? '',
        'countryCode': offerData['countryCode'] ?? 'QA',
        'zoneId': offerData['zoneId'] ?? '',

        // Metadata
        'notes': notes,
        'source': 'app',

        // Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Create reservation
      transaction.set(reservationRef, reservationData);

      // Increment offer.bookedSlots
      transaction.update(offerRef, {
        'bookedSlots': bookedSlots + quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Reservation created: ${reservationRef.id}');
    });

    return reservationRef.id;
  }

  // ═══════════════════════════════════════════════════════
  // CANCEL RESERVATION
  // ═══════════════════════════════════════════════════════
  Future<void> cancelReservation(String reservationId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not signed in');

      await _db.runTransaction((transaction) async {
        final ref = _reservations.doc(reservationId);
        final snap = await transaction.get(ref);
        if (!snap.exists) throw Exception('Reservation not found');

        final data = snap.data() as Map<String, dynamic>;
        if (data['userUid'] != uid) {
          throw Exception('Not your reservation');
        }
        if (data['status'] != 'reserved') {
          throw Exception('Cannot cancel: ${data['status']}');
        }

        final offerId = data['offerId'] as String? ?? '';
        final quantity = (data['quantity'] as num?)?.toInt() ?? 1;
        final offerRef = _offers.doc(offerId);
        final offerSnap = await transaction.get(offerRef);

        // Update reservation
        transaction.update(ref, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Decrement offer.bookedSlots
        if (offerSnap.exists) {
          final offerData = offerSnap.data() as Map<String, dynamic>;
          final bookedSlots = (offerData['bookedSlots'] as num?)?.toInt() ?? 0;
          transaction.update(offerRef, {
            'bookedSlots': max(0, bookedSlots - quantity),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      debugPrint('✅ Reservation cancelled');
    } catch (e) {
      debugPrint('❌ cancelReservation error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════
  // MARK PICKED UP (Shop side)
  // ═══════════════════════════════════════════════════════
  Future<void> markPickedUp(String reservationId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not signed in');

      final ref = _reservations.doc(reservationId);
      final snap = await ref.get();
      if (!snap.exists) throw Exception('Reservation not found');

      final data = snap.data() as Map<String, dynamic>;
      if (data['status'] != 'reserved') {
        throw Exception('Cannot mark: ${data['status']}');
      }

      await ref.update({
        'status': 'picked_up',
        'pickedUpAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Marked as picked up');
    } catch (e) {
      debugPrint('❌ markPickedUp error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════
  // MARK NO-SHOW (Shop side)
  // ═══════════════════════════════════════════════════════
  Future<void> markNoShow(String reservationId, {String reason = 'manual'}) async {
    try {
      final ref = _reservations.doc(reservationId);
      final snap = await ref.get();
      if (!snap.exists) throw Exception('Reservation not found');

      final data = snap.data() as Map<String, dynamic>;
      if (data['status'] != 'reserved') {
        throw Exception('Cannot mark: ${data['status']}');
      }

      final uid = data['userUid'] as String? ?? '';
      final quantity = (data['quantity'] as num?)?.toInt() ?? 1;
      final offerId = data['offerId'] as String? ?? '';

      await _db.runTransaction((transaction) async {
        // Update reservation
        transaction.update(ref, {
          'status': 'expired',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Release offer slots
        final offerRef = _offers.doc(offerId);
        final offerSnap = await transaction.get(offerRef);
        if (offerSnap.exists) {
          final offerData = offerSnap.data() as Map<String, dynamic>;
          final bookedSlots = (offerData['bookedSlots'] as num?)?.toInt() ?? 0;
          transaction.update(offerRef, {
            'bookedSlots': max(0, bookedSlots - quantity),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Log no-show
      await _noShowLog.add({
        'userUid': uid,
        'userName': data['userName'] ?? '',
        'businessId': data['businessId'] ?? '',
        'businessName': data['businessName'] ?? '',
        'offerId': offerId,
        'reservationId': reservationId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Check escalation (async, don't await)
      _checkNoShowEscalation(uid).catchError((e) {
        debugPrint('⚠️ escalation check: $e');
      });

      debugPrint('✅ Marked as no-show');
    } catch (e) {
      debugPrint('❌ markNoShow error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════
  // NO-SHOW ESCALATION
  // ═══════════════════════════════════════════════════════
  Future<void> _checkNoShowEscalation(String uid) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final snap = await _noShowLog
          .where('userUid', isEqualTo: uid)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final count = snap.docs.length;
      final config = await getConfig();

      if (count >= config.noShowLimit30Day) {
        // 30-day ban
        await _createBan(uid, count, 30);
      } else if (count >= config.noShowLimit7Day) {
        // 7-day ban
        await _createBan(uid, count, 7);
      }
    } catch (e) {
      debugPrint('⚠️ _checkNoShowEscalation error: $e');
    }
  }

  Future<void> _createBan(String uid, int noShowCount, int days) async {
    try {
      final bannedUntil = DateTime.now().add(Duration(days: days));
      await _bans.doc(uid).set({
        'userUid': uid,
        'bannedUntil': Timestamp.fromDate(bannedUntil),
        'reason': '$noShowCount no-shows in 30 days',
        'noShowCount': noShowCount,
        'createdBy': 'system',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('🚫 Ban created: $days days');
    } catch (e) {
      debugPrint('❌ _createBan error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════
  // STREAMS
  // ═══════════════════════════════════════════════════════
  Stream<List<ReservationModel>> streamMyReservations(String uid) {
    return _reservations
        .where('userUid', isEqualTo: uid)
        .orderBy('bookedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReservationModel.fromMap(
                  d.id,
                  d.data() as Map<String, dynamic>,
                ))
            .toList());
  }

  Stream<List<ReservationModel>> streamBusinessReservations(String businessId) {
    return _reservations
        .where('businessId', isEqualTo: businessId)
        .orderBy('bookedAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReservationModel.fromMap(
                  d.id,
                  d.data() as Map<String, dynamic>,
                ))
            .toList());
  }

  // ═══════════════════════════════════════════════════════
  // QR / CODE HELPERS
  // ═══════════════════════════════════════════════════════
  String _generateUUID() {
    final rand = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(32, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  String _generate6DigitCode() {
    final rand = Random.secure();
    return (100000 + rand.nextInt(900000)).toString();
  }

  Future<ReservationModel?> validateQRCode(
    String qrCode,
    String businessId,
  ) async {
    try {
      final snap = await _reservations
          .where('qrCode', isEqualTo: qrCode)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      final res = ReservationModel.fromMap(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );

      if (res.businessId != businessId) return null;
      if (!res.isActive) return null;
      if (res.expiresAt.isBefore(DateTime.now())) return null;

      return res;
    } catch (e) {
      debugPrint('⚠️ validateQRCode error: $e');
      return null;
    }
  }

  /// Validate reservation by 6-digit pickup code.
  /// Used when customer cannot show QR (e.g., phone battery dead).
  Future<ReservationModel?> validateByPickupCode(
    String pickupCode,
    String businessId,
  ) async {
    try {
      final snap = await _reservations
          .where('businessId', isEqualTo: businessId)
          .where('pickupCode', isEqualTo: pickupCode)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      final res = ReservationModel.fromMap(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );
      if (!res.isActive) return null;
      if (res.expiresAt.isBefore(DateTime.now())) return null;

      return res;
    } catch (e) {
      debugPrint('⚠️ validateByPickupCode error: $e');
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════
// CAN BOOK RESULT
// ═══════════════════════════════════════════════════════
class CanBookResult {
  final bool canBook;
  final String? reason;
  final int? remainingSlots;
  final bool needsRulesAcceptance;
  final String? rulesVersion;
  final ReservationConfigModel? config;
  final ReservationRulesModel? rules;

  CanBookResult({
    required this.canBook,
    this.reason,
    this.remainingSlots,
    this.needsRulesAcceptance = false,
    this.rulesVersion,
    this.config,
    this.rules,
  });
}