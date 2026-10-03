import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business_model.dart';
import '../models/claim_model.dart';
import '../models/offer_model.dart';
import '../models/user_model.dart';

/// All Firestore reads/writes for MIGO go through here.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- USERS ----------

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<UserModel?> getUser(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserModel.fromMap(uid, snap.data()!);
  }

  Stream<UserModel?> streamUser(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserModel.fromMap(uid, snap.data()!);
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> addCoins({
    required String uid,
    required int amount,
    required String reason,
  }) async {
    await _users.doc(uid).set(
      {
        'coins': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await _db.collection('coin_transactions').add({
      'uid': uid,
      'amount': amount,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------- BUSINESSES ----------

  CollectionReference<Map<String, dynamic>> get _businesses =>
      _db.collection('businesses');

  Future<String> createBusiness(BusinessModel business) async {
    final ref = await _businesses.add(business.toMap());
    return ref.id;
  }

  Future<BusinessModel?> getBusiness(String id) async {
    final snap = await _businesses.doc(id).get();
    if (!snap.exists || snap.data() == null) return null;
    return BusinessModel.fromMap(id, snap.data()!);
  }

  Stream<BusinessModel?> streamMyBusiness(String ownerUid) {
    return _businesses
        .where('ownerUid', isEqualTo: ownerUid)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return BusinessModel.fromMap(doc.id, doc.data());
    });
  }

  Future<void> updateBusiness(String id, Map<String, dynamic> data) async {
    await _businesses.doc(id).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ---------- OFFERS ----------

  CollectionReference<Map<String, dynamic>> get _offers =>
      _db.collection('offers');

  Future<String> createOffer(OfferModel offer) async {
    final ref = await _offers.add(offer.toMap());
    return ref.id;
  }

  Future<OfferModel?> getOffer(String id) async {
    final snap = await _offers.doc(id).get();
    if (!snap.exists || snap.data() == null) return null;
    return OfferModel.fromMap(id, snap.data()!);
  }

  Stream<List<OfferModel>> streamMyOffers(String businessId) {
    return _offers
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => OfferModel.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<OfferModel>> streamLiveOffers({int limit = 20}) {
    return _offers
        .where('status', isEqualTo: 'live')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => OfferModel.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<OfferModel>> streamLiveOffersByType(
    String type, {
    int limit = 10,
  }) {
    return _offers
        .where('status', isEqualTo: 'live')
        .where('type', isEqualTo: type)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => OfferModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> updateOffer(String id, Map<String, dynamic> data) async {
    await _offers.doc(id).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ---------- CLAIMS ----------

  CollectionReference<Map<String, dynamic>> get _claims =>
      _db.collection('claims');

  /// Create a claim. Returns the new claim ID.
  /// Also increments offer's claimedCount and awards coins to user.
  Future<String> createClaim(ClaimModel claim) async {
    final ref = await _claims.add(claim.toMap());

    // Increment claimed count on the offer
    await _offers.doc(claim.offerId).update({
      'claimedCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Award coins for claiming
    await addCoins(
      uid: claim.userUid,
      amount: 5,
      reason: 'Claimed "${claim.offerTitle}"',
    );

    return ref.id;
  }

  /// Has this user already claimed this offer (active or redeemed)?
  Future<ClaimModel?> findActiveClaim({
    required String userUid,
    required String offerId,
  }) async {
    final snap = await _claims
        .where('userUid', isEqualTo: userUid)
        .where('offerId', isEqualTo: offerId)
        .limit(10)
        .get();

    for (final doc in snap.docs) {
      final claim = ClaimModel.fromMap(doc.id, doc.data());
      if (claim.status == ClaimStatus.active ||
          claim.status == ClaimStatus.redeemed) {
        return claim;
      }
    }
    return null;
  }

  /// Stream all claims for a user (newest first not guaranteed without index).
  Stream<List<ClaimModel>> streamMyClaims(String userUid) {
    return _claims
        .where('userUid', isEqualTo: userUid)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ClaimModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> updateClaim(String id, Map<String, dynamic> data) async {
    await _claims.doc(id).update({
      ...data,
    });
  }
}