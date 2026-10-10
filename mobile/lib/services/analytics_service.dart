import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// MIGO Analytics Service
///
/// Logs customer behavior events to Firestore (`customer_behavior`).
/// All events are fire-and-forget (no await on caller side needed).
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Log an event. Silent fail (never throw).
  Future<void> logEvent({
    required String eventType,
    String? offerId,
    String? businessId,
    String? category,
    String? query,
    String? areaId,
    String? countryCode,
    String? currency,
    String? source,
    Map<String, dynamic>? extra,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return; // not signed in — skip

      await _db.collection('customer_behavior').add({
        'userUid': uid,
        'eventType': eventType,
        'offerId': offerId,
        'businessId': businessId,
        'category': category,
        'query': query,
        'areaId': areaId,
        'countryCode': countryCode,
        'currency': currency,
        'source': source ?? 'app',
        'extra': ?extra,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Silent fail — analytics should never break the app
    }
  }

  // ─── Convenience methods ─────────────────────

  Future<void> logViewOffer({
    required String offerId,
    required String businessId,
    String? category,
    String? areaId,
    String? countryCode,
  }) =>
      logEvent(
        eventType: 'view_offer',
        offerId: offerId,
        businessId: businessId,
        category: category,
        areaId: areaId,
        countryCode: countryCode,
      );

  Future<void> logSearch({
    required String query,
    String? category,
    String? areaId,
  }) =>
      logEvent(
        eventType: 'search',
        query: query,
        category: category,
        areaId: areaId,
      );

  Future<void> logSaveOffer({
    required String offerId,
    required String businessId,
  }) =>
      logEvent(
        eventType: 'save_offer',
        offerId: offerId,
        businessId: businessId,
      );

  Future<void> logSaveBusiness({required String businessId}) =>
      logEvent(eventType: 'save_business', businessId: businessId);

  Future<void> logViewBusiness({
    required String businessId,
    String? category,
  }) =>
      logEvent(
        eventType: 'view_business',
        businessId: businessId,
        category: category,
      );
}