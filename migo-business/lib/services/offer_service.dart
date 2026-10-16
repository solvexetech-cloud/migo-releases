import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/offer_model.dart';

/// PHASE I — Offer Service (Business App)
class OfferService {
  OfferService._();
  static final OfferService instance = OfferService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream business's offers
  Stream<List<OfferModel>> streamMyOffers(String businessId) {
    return _db
        .collection('offers')
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => OfferModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Create new offer
  Future<String?> createOffer({
    required String businessId,
    required String businessName,
    required String areaId,
    required String title,
    required String description,
    required String category,
    required String imageUrl,
    required double originalPrice,
    required double offerPrice,
    required String currency,
    required String type,
    DateTime? startDate,
    DateTime? endDate,
    bool reserveEnabled = false,
    int totalStock = 0,
    int maxPerCustomer = 1,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return 'Not signed in';

      await _db.collection('offers').add({
        'businessId': businessId,
        'businessName': businessName,
        'areaId': areaId,
        'title': title,
        'description': description,
        'category': category,
        'imageUrl': imageUrl,
        'originalPrice': originalPrice,
        'offerPrice': offerPrice,
        'currency': currency,
        'type': type,
        'status': 'pending', // Needs admin approval
        'startDate': startDate != null
            ? Timestamp.fromDate(startDate)
            : null,
        'endDate':
            endDate != null ? Timestamp.fromDate(endDate) : null,
        'reserveEnabled': reserveEnabled,
        'totalStock': totalStock,
        'bookedSlots': 0,
        'claimedCount': 0,
        'maxPerCustomer': maxPerCustomer,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return null; // Success
    } catch (e) {
      return 'Failed: $e';
    }
  }

  /// Update offer
  Future<String?> updateOffer({
    required String offerId,
    required String title,
    required String description,
    required String category,
    required String imageUrl,
    required double originalPrice,
    required double offerPrice,
    DateTime? endDate,
  }) async {
    try {
      await _db.collection('offers').doc(offerId).update({
        'title': title,
        'description': description,
        'category': category,
        'imageUrl': imageUrl,
        'originalPrice': originalPrice,
        'offerPrice': offerPrice,
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Failed: $e';
    }
  }

    /// Toggle active/inactive
  Future<String?> toggleActive({
    required String offerId,
    required bool currentActive,
  }) async {
    try {
      await _db.collection('offers').doc(offerId).update({
        'status': currentActive ? 'paused' : 'live',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Failed: $e';
    }
  }

  /// Delete offer
  Future<String?> deleteOffer(String offerId) async {
    try {
      await _db.collection('offers').doc(offerId).delete();
      return null;
    } catch (e) {
      return 'Failed: $e';
    }
  }
}