import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/demand_model.dart';
import '../models/demand_bid_model.dart';
import '../models/demand_claim_model.dart';
import 'dart:math';

class DemandService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔍 1. Find a similar existing demand using fuzzy matching
  Future<Map<String, dynamic>?> findSimilarDemand({
    required String title,
    required double targetPrice,
    required String areaId,
    required String category,
  }) async {
    try {
      final querySnapshot = await _db
          .collection('demands')
          .where('areaId', isEqualTo: areaId)
          .where('category', isEqualTo: category)
          .where('isPrivate', isEqualTo: false)
          .where('status', isEqualTo: 'open')
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final normalizedNewTitle = _normalizeText(title);
      final newBrand = _extractBrand(normalizedNewTitle);
      final newStorage = _extractStorage(normalizedNewTitle);

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final existingTitle = data['title']?['en'] ?? '';
        final normalizedExistingTitle = _normalizeText(existingTitle);
        
        final existingBrand = _extractBrand(normalizedExistingTitle);
        final existingStorage = _extractStorage(normalizedExistingTitle);

        if (newBrand != null && existingBrand != null && newBrand != existingBrand) continue;
        if (newStorage != null && existingStorage != null && newStorage != existingStorage) continue;

        final similarity = _calculateSimilarity(normalizedNewTitle, normalizedExistingTitle);
        
        final existingPrice = (data['targetPrice'] as num?)?.toDouble() ?? 0.0;
        bool priceMatches = false;
        if (targetPrice > 0 && existingPrice > 0) {
          final priceDiff = (targetPrice - existingPrice).abs();
          final maxPrice = targetPrice > existingPrice ? targetPrice : existingPrice;
          if ((priceDiff / maxPrice) <= 0.20) priceMatches = true;
        }

        if (similarity > 0.70 || (similarity > 0.55 && priceMatches)) {
          return {
            'id': doc.id,
            'title': existingTitle,
            'targetPrice': existingPrice,
            'currentCount': data['currentCount'] ?? 0,
            'minRequiredCount': data['minRequiredCount'] ?? 15,
          };
        }
      }
      return null;
    } catch (e) {
      print('Error finding similar demand: $e');
      return null;
    }
  }

  // 2. Create a new Demand
  Future<String?> createDemand({
    required Map<String, String> title,
    required Map<String, String> description,
    required double targetPrice,
    required String currency,
    required String areaId,
    required String category,
    required bool isPrivate,
    required int quantity,
    DateTime? deliveryDate,
    String? joinExistingDemandId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      if (joinExistingDemandId != null) {
        await joinDemand(joinExistingDemandId);
        return joinExistingDemandId;
      }

      final docRef = _db.collection('demands').doc();
      final demand = DemandModel(
        id: docRef.id,
        userId: user.uid,
        userName: user.displayName ?? 'User',
        title: title,
        description: description,
        targetPrice: targetPrice,
        currency: currency,
        minRequiredCount: 15,
        currentCount: 1,
        status: 'open',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 14)),
        areaId: areaId,
        category: category,
        isPrivate: isPrivate,
        quantity: quantity,
        deliveryDate: deliveryDate,
      );

      await docRef.set(demand.toMap());

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

  // 3. Join an existing Demand
  Future<bool> joinDemand(String demandId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final demandRef = _db.collection('demands').doc(demandId);
      
      return await _db.runTransaction((transaction) async {
        final demandSnap = await transaction.get(demandRef);
        if (!demandSnap.exists) return false;

        final data = demandSnap.data()!;
        final currentCount = data['currentCount'] ?? 0;
        final status = data['status'] ?? 'open';

        if (status != 'open') return false; 

        final joinQuery = await _db.collection('demand_joins')
            .where('demandId', isEqualTo: demandId)
            .where('userId', isEqualTo: user.uid)
            .get();
        
        if (joinQuery.docs.isNotEmpty) return false; 

        transaction.update(demandRef, {
          'currentCount': currentCount + 1,
        });

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

  // 4. Get Demands Stream
  Stream<QuerySnapshot> getDemandsStream({String? status, String? areaId, String? category, bool? isPrivate, String? userId}) {
    Query query = _db.collection('demands').orderBy('createdAt', descending: true);
    if (status != null) query = query.where('status', isEqualTo: status);
    if (areaId != null) query = query.where('areaId', isEqualTo: areaId);
    if (category != null) query = query.where('category', isEqualTo: category);
    if (isPrivate != null) query = query.where('isPrivate', isEqualTo: isPrivate);
    if (userId != null) query = query.where('userId', isEqualTo: userId);
    return query.snapshots();
  }

  // 5. Place a Bid (Vendor)
  Future<bool> placeBid({
    required String demandId,
    required String businessId,
    required Map<String, String> businessName,
    required double offerPrice,
    required String authenticity,
    required String fulfillmentType,
    required double businessTrustScore,
    required int minCommitments,
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
        status: 'approved',
        businessTrustScore: businessTrustScore,
        adminNotes: {'en': '', 'ar': ''},
        createdAt: DateTime.now(),
        minCommitments: minCommitments,
      );

      await docRef.set(bid.toMap());
      return true;
    } catch (e) {
      print('Error placing bid: $e');
      return false;
    }
  }

  // 6. Get Bids for a Demand
  Stream<QuerySnapshot> getBidsStream(String demandId) {
    return _db.collection('demand_bids')
        .where('demandId', isEqualTo: demandId)
        .where('status', isEqualTo: 'approved')
        .orderBy('offerPrice', descending: false)
        .snapshots();
  }

  // 7. Commit to Offer (Instead of Lock Deal)
  Future<String> commitToOffer({
    required String demandId,
    required String bidId,
    required String businessId,
    required Map<String, String> businessName,
    required double finalPrice,
    required String fulfillmentType,
    required int minCommitments,
    String? deliveryAddress,
    String? deliveryPhone,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'error';

      final batch = _db.batch();
      
      final commitRef = _db.collection('demand_commits').doc();
      batch.set(commitRef, {
        'demandId': demandId,
        'bidId': bidId,
        'userId': user.uid,
        'businessId': businessId,
        'businessName': businessName,
        'finalPrice': finalPrice,
        'fulfillmentType': fulfillmentType,
        'deliveryAddress': deliveryAddress,
        'deliveryPhone': deliveryPhone,
        'status': 'committed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final bidRef = _db.collection('demand_bids').doc(bidId);
      batch.update(bidRef, {
        'commitCount': FieldValue.increment(1),
      });

      await batch.commit();

      final bidSnap = await bidRef.get();
      final currentCommits = (bidSnap.data()?['commitCount'] as num?)?.toInt() ?? 0;

      if (currentCommits >= minCommitments) {
        final pin = (Random().nextInt(900000) + 100000).toString(); 
        final qrData = 'MIGO_DEMAND_${demandId}_${user.uid}_$pin';

        final claimRef = _db.collection('demand_claims').doc();
        final claim = DemandClaimModel(
          id: claimRef.id,
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
          expiresAt: DateTime.now().add(const Duration(days: 2)),
        );

        await claimRef.set(claim.toMap());

        await commitRef.update({'status': 'locked', 'claimId': claimRef.id});
        
        return 'locked'; 
      } else {
        return 'waiting'; 
      }
    } catch (e) {
      print('Error committing to offer: $e');
      return 'error';
    }
  }

  // =========================================================================
  // 🧠 HELPER FUNCTIONS FOR FUZZY MATCHING
  // =========================================================================

  String _normalizeText(String s) {
    return s.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _extractBrand(String text) {
    final brands = ['apple', 'iphone', 'samsung', 'galaxy', 'huawei', 'xiaomi', 'redmi', 'oppo', 'vivo', 'oneplus', 'sony', 'dell', 'hp', 'lenovo', 'nike', 'adidas'];
    for (var b in brands) { if (text.contains(b)) return b; }
    return null;
  }

  double? _extractStorage(String text) {
    final match = RegExp(r'(\d+)\s*(tb|gb)').firstMatch(text);
    if (match != null) {
      double num = double.parse(match.group(1)!);
      if (match.group(2) == 'tb') num *= 1024;
      return num;
    }
    return null;
  }

  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    final setA = a.split(' ').toSet();
    final setB = b.split(' ').toSet();
    if (setA.isEmpty || setB.isEmpty) return 0.0;
    final intersection = setA.intersection(setB).length;
    return (2.0 * intersection) / (setA.length + setB.length);
  }
}