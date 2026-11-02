import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/demand_model.dart';
import '../models/demand_bid_model.dart';
import '../models/demand_claim_model.dart';
import 'dart:math';

class DemandService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Create a new Demand
  Future<String?> createDemand({
    required Map<String, String> title,
    required Map<String, String> description,
    required double targetPrice,
    required int requiredCount,
    required String currency,
    required String areaId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final docRef = _db.collection('demands').doc();
      final demand = DemandModel(
        id: docRef.id,
        userId: user.uid,
        userName: user.displayName ?? 'User',
        title: title,
        description: description,
        targetPrice: targetPrice,
        currency: currency,
        requiredCount: requiredCount,
        currentCount: 1, // Creator is the first person
        status: 'open',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 3)), // 3 days limit
        areaId: areaId,
      );

      await docRef.set(demand.toMap());

      // Add creator to demand_joins
      await _db.collection('demand_joins').add({
        'demandId': docRef.id,
        'userId': user.uid,
        'userName': user.displayName ?? 'User',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Error creating demand: $e');
      return null;
    }
  }

  // 2. Join an existing Demand
  Future<bool> joinDemand(String demandId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final demandRef = _db.collection('demands').doc(demandId);
      
      // Use a transaction to avoid race conditions
      return await _db.runTransaction((transaction) async {
        final demandSnap = await transaction.get(demandRef);
        if (!demandSnap.exists) return false;

        final data = demandSnap.data()!;
        final currentCount = data['currentCount'] ?? 0;
        final requiredCount = data['requiredCount'] ?? 1;
        final status = data['status'] ?? 'open';

        if (status != 'open') return false; // Cannot join if threshold reached or locked

        // Check if user already joined
        final joinQuery = await _db.collection('demand_joins')
            .where('demandId', isEqualTo: demandId)
            .where('userId', isEqualTo: user.uid)
            .get();
        
        if (joinQuery.docs.isNotEmpty) return false; // Already joined

        final newCount = currentCount + 1;
        final newStatus = newCount >= requiredCount ? 'threshold_reached' : 'open';

        transaction.update(demandRef, {
          'currentCount': newCount,
          'status': newStatus,
        });

        // Add to joins
        final joinRef = _db.collection('demand_joins').doc();
        transaction.set(joinRef, {
          'demandId': demandId,
          'userId': user.uid,
          'userName': user.displayName ?? 'User',
          'joinedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      print('Error joining demand: $e');
      return false;
    }
  }

  // 3. Get Demands Stream (Filtered by status or area)
  Stream<QuerySnapshot> getDemandsStream({String? status, String? areaId}) {
    Query query = _db.collection('demands').orderBy('createdAt', descending: true);
    
    if (status != null) query = query.where('status', isEqualTo: status);
    if (areaId != null) query = query.where('areaId', isEqualTo: areaId);

    return query.snapshots();
  }

  // 4. Place a Bid (Vendor)
  Future<bool> placeBid({
    required String demandId,
    required String businessId,
    required Map<String, String> businessName,
    required double offerPrice,
    required String authenticity, // 'Original' or 'Master Copy'
    required String fulfillmentType, // 'Store Pickup' or 'Home Delivery'
    required double businessTrustScore,
  }) async {
    try {
      final docRef = _db.collection('demand_bids').doc();
      final bid = DemandBidModel(
        id: docRef.id,
        demandId: demandId,
        businessId: businessId,
        businessName: businessName,
        offerPrice: offerPrice,
        authenticity: authenticity,
        fulfillmentType: fulfillmentType,
        status: 'pending',
        businessTrustScore: businessTrustScore,
        adminNotes: {'en': '', 'ar': ''},
        createdAt: DateTime.now(),
      );

      await docRef.set(bid.toMap());
      return true;
    } catch (e) {
      print('Error placing bid: $e');
      return false;
    }
  }

  // 5. Get Bids for a Demand
  Stream<QuerySnapshot> getBidsStream(String demandId) {
    return _db.collection('demand_bids')
        .where('demandId', isEqualTo: demandId)
        .where('status', isEqualTo: 'approved') // Only show approved bids to customer
        .orderBy('offerPrice', descending: false) // Lowest price first
        .snapshots();
  }

  // 6. Lock Deal (Customer selects a vendor)
  Future<bool> lockDeal({
    required String demandId,
    required String bidId,
    required String businessId,
    required Map<String, String> businessName,
    required double finalPrice,
    required String fulfillmentType,
    String? deliveryAddress,
    String? deliveryPhone,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Generate 6-digit PIN and unique QR string
      final pin = (Random().nextInt(900000) + 100000).toString(); // 100000 - 999999
      final qrData = 'MIGO_DEMAND_${demandId}_${user.uid}_$pin';

      final docRef = _db.collection('demand_claims').doc();
      final claim = DemandClaimModel(
        id: docRef.id,
        demandId: demandId,
        bidId: bidId,
        userId: user.uid,
        businessId: businessId,
        businessName: businessName,
        finalPrice: finalPrice,
        fulfillmentType: fulfillmentType,
        deliveryAddress: deliveryAddress,
        deliveryPhone: deliveryPhone,
        redemptionPin: pin,
        qrData: qrData,
        status: 'locked',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 2)), // 48 hours to redeem
      );

      await docRef.set(claim.toMap());
      
      return true;
    } catch (e) {
      print('Error locking deal: $e');
      return false;
    }
  }
}