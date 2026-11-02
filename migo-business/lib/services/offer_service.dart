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
    required String titleEn,
    required String titleAr,
    required String description,
    required String descriptionEn,
    required String descriptionAr,
    required String category,
    required String imageUrl,
    required double originalPrice,
    required double offerPrice,
    required String currency,
    required String type,
    DateTime? startDate,
    DateTime? endDate,
    String? countryCode,
    String? whatsappNumber,
    String? orderLink,
    // 🆕 Group deal fields (Plan A & Plan B)
    int? requiredClaims,
    int? maxSlots,
    int? groupTimerHours,
    int? redemptionWindowHours,
    double? floorPrice,
    double? stepPrice,
    bool? lockOnSlotsFull,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return 'Not signed in';

      // ബിസിനസ്സിന്റെ രാജ്യം എടുക്കാൻ
      String finalCountry = countryCode ?? 'QA';
      if (countryCode == null || countryCode.isEmpty) {
        final bizSnap = await _db.collection('businesses').doc(businessId).get();
        finalCountry = bizSnap.data()?['countryCode'] as String? ?? 'QA';
      }

      // 🆕 Group deal ആണെങ്കിൽ മാത്രം ഫീൽഡുകൾ ചേർക്കുക
      final isGroupDeal =
          type == 'group_all_or_nothing' || type == 'group_progressive';

      final Map<String, dynamic> data = {
        // Core fields
        'businessId': businessId,
        'businessName': businessName,
        'areaId': areaId.trim().toLowerCase(),
        'businessAreaId': areaId.trim().toLowerCase(),
        'title': title,
        'titleEn': titleEn,
        'titleAr': titleAr,
        'description': description,
        'descriptionEn': descriptionEn,
        'descriptionAr': descriptionAr,
        'category': category,
        'imageUrl': imageUrl,
        'originalPrice': originalPrice,
        'offerPrice': offerPrice,
        'currency': currency,
        'type': type,
        'countryCode': finalCountry,
        'whatsappNumber': whatsappNumber ?? '',
        'orderLink': orderLink ?? '',

        // Status
        'status': 'pending',

        // Dates
        'startAt': startDate != null ? Timestamp.fromDate(startDate) : FieldValue.serverTimestamp(),
        'endAt': endDate != null ? Timestamp.fromDate(endDate) : null,
        'startDate': startDate != null ? Timestamp.fromDate(startDate) : null,
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,

        // Reserve settings
        'reserveEnabled': false,
        'totalStock': 0,
        'totalSlots': 0,
        'bookedSlots': 0,
        'maxPerCustomer': 1,
        'reserve': {
          'enabled': false,
          'totalSlots': 0,
          'holdHours': 6,
          'tokenRequired': false,
          'maxPerCustomer': 1,
        },

        // Counters
        'claimedCount': 0,

        // 🆕 Group deal state
        'dealState': isGroupDeal ? 'OPEN' : 'DRAFT',

        // Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 🆕 Group deal fields — null അല്ലാത്തവ മാത്രം ചേർക്കുക
      if (isGroupDeal) {
        if (requiredClaims != null) data['requiredClaims'] = requiredClaims;
        if (maxSlots != null) data['maxSlots'] = maxSlots;
        if (groupTimerHours != null) data['groupTimerHours'] = groupTimerHours;
        if (redemptionWindowHours != null) {
          data['redemptionWindowHours'] = redemptionWindowHours;
        }
        if (floorPrice != null) data['floorPrice'] = floorPrice;
        if (stepPrice != null) data['stepPrice'] = stepPrice;
        if (lockOnSlotsFull != null) {
          data['lockOnSlotsFull'] = lockOnSlotsFull;
        }
      }

      await _db.collection('offers').add(data);

      return null; // Success
    } catch (e) {
      return 'Failed: $e';
    }
  }

  /// Update offer
  Future<String?> updateOffer({
    required String offerId,
    required String title,
    required String titleEn,
    required String titleAr,
    required String description,
    required String descriptionEn,
    required String descriptionAr,
    required String category,
    required String type,
    required String imageUrl,
    required double originalPrice,
    required double offerPrice,
    DateTime? endDate,
    String? whatsappNumber,
    String? orderLink,
    // 🆕 Group deal fields
    int? requiredClaims,
    int? maxSlots,
    int? groupTimerHours,
    int? redemptionWindowHours,
    double? floorPrice,
    double? stepPrice,
    bool? lockOnSlotsFull,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'title': title,
        'titleEn': titleEn,
        'titleAr': titleAr,
        'description': description,
        'descriptionEn': descriptionEn,
        'descriptionAr': descriptionAr,
        'category': category,
        'type': type,
        'imageUrl': imageUrl,
        'originalPrice': originalPrice,
        'offerPrice': offerPrice,
        'endAt': endDate != null ? Timestamp.fromDate(endDate) : null,
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
        'whatsappNumber': whatsappNumber ?? '',
        'orderLink': orderLink ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 🆕 Group deal fields — null അല്ലാത്തവ മാത്രം അപ്ഡേറ്റ് ചെയ്യുക
      // (null ആയാൽ പഴയ മൂല്യം നിലനിർത്തും)
      if (requiredClaims != null) data['requiredClaims'] = requiredClaims;
      if (maxSlots != null) data['maxSlots'] = maxSlots;
      if (groupTimerHours != null) data['groupTimerHours'] = groupTimerHours;
      if (redemptionWindowHours != null) {
        data['redemptionWindowHours'] = redemptionWindowHours;
      }
      if (floorPrice != null) data['floorPrice'] = floorPrice;
      if (stepPrice != null) data['stepPrice'] = stepPrice;
      if (lockOnSlotsFull != null) {
        data['lockOnSlotsFull'] = lockOnSlotsFull;
      }

      await _db.collection('offers').doc(offerId).update(data);
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