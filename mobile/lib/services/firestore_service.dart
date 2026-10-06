import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business_model.dart';
import '../models/category_model.dart';
import '../models/claim_model.dart';
import '../models/coin_transaction_model.dart';
import '../models/group_deal_model.dart';
import '../models/notification_model.dart';
import '../models/offer_model.dart';
import '../models/referral_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';

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
      {...data, 'updatedAt': FieldValue.serverTimestamp()},
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

  // ---------- COIN TRANSACTIONS ----------
  Stream<List<CoinTransactionModel>> streamCoinTransactions(
    String uid, {
    int limit = 30,
  }) {
    return _db
        .collection('coin_transactions')
        .where('uid', isEqualTo: uid)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => CoinTransactionModel.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
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

  Stream<BusinessModel?> streamMyBusinessById(String businessId) {
    return _businesses.doc(businessId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return BusinessModel.fromMap(businessId, snap.data()!);
    });
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
      {...data, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  // ---------- CATEGORIES ----------
  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection('categories');

  Stream<List<CategoryModel>> streamCategories({
    bool onlyActive = true,
  }) {
    return _categories.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => CategoryModel.fromMap(d.id, d.data()))
          .where((c) => !onlyActive || c.active)
          .toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  Future<List<CategoryModel>> getCategories({
    bool onlyActive = true,
  }) async {
    final snap = await _categories.limit(50).get();
    final list = snap.docs
        .map((d) => CategoryModel.fromMap(d.id, d.data()))
        .where((c) => !onlyActive || c.active)
        .toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  Future<void> createCategory({
    required String name,
    required String icon,
    int order = 99,
  }) async {
    final docId = name.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    await _categories.doc(docId).set({
      'name': name,
      'icon': icon,
      'order': order,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategory(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _categories.doc(id).set(
      {...data, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> deleteCategory(String id) async {
    await _categories.doc(id).delete();
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
        .map((snap) {
      final now = DateTime.now();
      final list = snap.docs
          .map((d) => OfferModel.fromMap(d.id, d.data()))
          .where((o) => o.endAt.isAfter(now))
          .toList();
      list.sort((a, b) => b.startAt.compareTo(a.startAt));
      return list;
    });
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
        .map((snap) {
      final now = DateTime.now();
      final list = snap.docs
          .map((d) => OfferModel.fromMap(d.id, d.data()))
          .where((o) => o.endAt.isAfter(now))
          .toList();
      list.sort((a, b) => b.startAt.compareTo(a.startAt));
      return list;
    });
  }

  Future<void> updateOffer(String id, Map<String, dynamic> data) async {
    await _offers.doc(id).set(
      {...data, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  // ---------- GROUP DEALS ----------
  CollectionReference<Map<String, dynamic>> get _groupDeals =>
      _db.collection('group_deals');

  Future<void> createGroupDeal(GroupDealModel deal) async {
    await _groupDeals.doc(deal.offerId).set(deal.toMap());
  }

  Future<GroupDealModel?> getGroupDeal(String offerId) async {
    final snap = await _groupDeals.doc(offerId).get();
    if (!snap.exists || snap.data() == null) return null;
    return GroupDealModel.fromMap(offerId, snap.data()!);
  }

  Stream<GroupDealModel?> streamGroupDeal(String offerId) {
    return _groupDeals.doc(offerId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return GroupDealModel.fromMap(offerId, snap.data()!);
    });
  }

  Future<void> joinGroupDeal({
    required String offerId,
    required String userUid,
  }) async {
    final ref = _groupDeals.doc(offerId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists || snap.data() == null) {
        throw Exception('Group deal not found.');
      }
      final deal = GroupDealModel.fromMap(offerId, snap.data()!);
      if (deal.status == GroupDealStatus.unlocked) {
        throw Exception('This deal is already unlocked.');
      }
      if (deal.status == GroupDealStatus.failed ||
          deal.status == GroupDealStatus.expired) {
        throw Exception('This group deal is closed.');
      }
      if (deal.deadline.isBefore(DateTime.now())) {
        throw Exception('This group deal has expired.');
      }
      if (deal.isFull) {
        throw Exception('This group deal is full.');
      }
      if (deal.participantUids.contains(userUid)) {
        throw Exception('You already joined this group.');
      }
      final updated = List<String>.from(deal.participantUids)..add(userUid);
      final meetsMin = updated.length >= deal.minParticipants;
      tx.update(ref, {
        'participantUids': updated,
        'updatedAt': FieldValue.serverTimestamp(),
        if (meetsMin) ...{
          'status': GroupDealStatus.unlocked.id,
          'unlockedAt': FieldValue.serverTimestamp(),
        },
      });
    });
  }

  Future<void> leaveGroupDeal({
    required String offerId,
    required String userUid,
  }) async {
    final ref = _groupDeals.doc(offerId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists || snap.data() == null) return;
      final deal = GroupDealModel.fromMap(offerId, snap.data()!);
      if (deal.status == GroupDealStatus.unlocked) {
        throw Exception('Cannot leave after the deal is unlocked.');
      }
      final updated = List<String>.from(deal.participantUids)
        ..remove(userUid);
      tx.update(ref, {
        'participantUids': updated,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---------- CLAIMS ----------
  CollectionReference<Map<String, dynamic>> get _claims =>
      _db.collection('claims');

  Future<String> createClaim(ClaimModel claim) async {
    final ref = await _claims.add(claim.toMap());
    await _offers.doc(claim.offerId).update({
      'claimedCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await addCoins(
      uid: claim.userUid,
      amount: 5,
      reason: 'Claimed "${claim.offerTitle}"',
    );

    await createNotification(
      NotificationModel.newDraft(
        userUid: claim.userUid,
        type: NotifType.coinEarned,
        title: '+5 MIGO Coins',
        body: 'You claimed "${claim.offerTitle}" at ${claim.businessName}.',
        targetRoute: 'claim',
        targetId: ref.id,
      ),
    );

    await _maybeRewardReferral(claim.userUid);

    return ref.id;
  }

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

  Stream<List<ClaimModel>> streamMyClaims(String userUid) {
    return _claims
        .where('userUid', isEqualTo: userUid)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ClaimModel.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<ClaimModel>> streamBusinessClaims(String businessId) {
    return _claims
        .where('businessId', isEqualTo: businessId)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ClaimModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> updateClaim(String id, Map<String, dynamic> data) async {
    await _claims.doc(id).update(data);
  }

  Future<void> redeemClaim({
    required String claimId,
    required String businessId,
  }) async {
    final snap = await _claims.doc(claimId).get();
    if (!snap.exists || snap.data() == null) {
      throw Exception('Claim not found');
    }
    final claim = ClaimModel.fromMap(claimId, snap.data()!);
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
    await _claims.doc(claimId).update({
      'status': ClaimStatus.redeemed.id,
      'redeemedAt': FieldValue.serverTimestamp(),
      'redeemedBy': businessId,
    });

    await addCoins(
      uid: claim.userUid,
      amount: 25,
      reason: 'Redeemed "${claim.offerTitle}"',
    );

    await createNotification(
      NotificationModel.newDraft(
        userUid: claim.userUid,
        type: NotifType.coinEarned,
        title: '+25 MIGO Coins',
        body:
            'Your "${claim.offerTitle}" was redeemed at ${claim.businessName}.',
        targetRoute: 'wallet',
      ),
    );
  }

  // ---------- REVIEWS ----------
  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection('reviews');

  Future<String> createReview(ReviewModel review) async {
    final ref = await _reviews.add(review.toMap());

    await addCoins(
      uid: review.userUid,
      amount: 10,
      reason: 'Wrote review for ${review.businessName}',
    );

    await createNotification(
      NotificationModel.newDraft(
        userUid: review.userUid,
        type: NotifType.coinEarned,
        title: '+10 MIGO Coins',
        body: 'Thanks for reviewing ${review.businessName}.',
        targetRoute: 'wallet',
      ),
    );

    final bizSnap = await _businesses.doc(review.businessId).get();
    final ownerUid = bizSnap.data()?['ownerUid'] as String?;
    if (ownerUid != null && ownerUid.isNotEmpty) {
      await createNotification(
        NotificationModel.newDraft(
          userUid: ownerUid,
          type: NotifType.newReview,
          title: 'New review on ${review.businessName}',
          body:
              '${review.userDisplayName} rated ${review.rating}★ — "${review.comment}"',
          targetRoute: 'business',
        ),
      );
    }

    return ref.id;
  }

  Future<bool> hasReviewedClaim(String claimId) async {
    final snap =
        await _reviews.where('claimId', isEqualTo: claimId).limit(1).get();
    return snap.docs.isNotEmpty;
  }

  Stream<List<ReviewModel>> streamBusinessReviews(String businessId) {
    return _reviews
        .where('businessId', isEqualTo: businessId)
        .limit(50)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ReviewModel.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) {
        final ad = a.createdAt ?? DateTime(2000);
        final bd = b.createdAt ?? DateTime(2000);
        return bd.compareTo(ad);
      });
      return list;
    });
  }

  Stream<List<ReviewModel>> streamMyReviews(String uid) {
    return _reviews
        .where('userUid', isEqualTo: uid)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReviewModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<({double average, int count})> getBusinessRating(
    String businessId,
  ) async {
    final snap = await _reviews
        .where('businessId', isEqualTo: businessId)
        .limit(200)
        .get();
    if (snap.docs.isEmpty) return (average: 0.0, count: 0);
    double sum = 0;
    for (final d in snap.docs) {
      sum += ((d.data()['rating'] as num?) ?? 0).toDouble();
    }
    return (average: sum / snap.docs.length, count: snap.docs.length);
  }

  // ---------- REFERRALS ----------
  CollectionReference<Map<String, dynamic>> get _referrals =>
      _db.collection('referrals');

  String generateReferralCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<String> ensureReferralCode(String uid) async {
    final snap = await _users.doc(uid).get();
    final existing = (snap.data()?['referralCode'] as String?) ?? '';
    if (existing.isNotEmpty) return existing;
    final code = generateReferralCode();
    await _users.doc(uid).set(
      {
        'referralCode': code,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    return code;
  }

  Future<String?> findUidByReferralCode(String code) async {
    final snap = await _users
        .where('referralCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Future<void> recordReferral({
    required String referrerUid,
    required String referredUid,
    required String referredEmail,
    required String referralCode,
  }) async {
    if (referrerUid == referredUid) {
      throw Exception('You cannot refer yourself.');
    }
    final existing = await _referrals
        .where('referredUid', isEqualTo: referredUid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;
    final ref = ReferralModel(
      id: '',
      referrerUid: referrerUid,
      referralCode: referralCode.toUpperCase(),
      referredUid: referredUid,
      referredEmail: referredEmail,
      createdAt: DateTime.now(),
    );
    await _referrals.add(ref.toMap());
    await _users.doc(referredUid).set(
      {
        'referredBy': referrerUid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<ReferralModel>> streamMyReferrals(String referrerUid) {
    return _referrals
        .where('referrerUid', isEqualTo: referrerUid)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReferralModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> _maybeRewardReferral(String uid) async {
    final userSnap = await _users.doc(uid).get();
    if (!userSnap.exists) return;
    final map = userSnap.data()!;
    final already = (map['hasCompletedFirstClaim'] ?? false) as bool;
    if (already) return;
    await _users.doc(uid).set(
      {
        'hasCompletedFirstClaim': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    final referredBy = map['referredBy'] as String?;
    if (referredBy == null || referredBy.isEmpty) return;
    final refSnap = await _referrals
        .where('referredUid', isEqualTo: uid)
        .where('referrerUid', isEqualTo: referredBy)
        .limit(1)
        .get();
    if (refSnap.docs.isEmpty) return;
    final refDoc = refSnap.docs.first;
    final referral = ReferralModel.fromMap(refDoc.id, refDoc.data());
    if (referral.status != ReferralStatus.pending) return;
    await _referrals.doc(refDoc.id).update({
      'status': ReferralStatus.rewarded.id,
      'rewardedAt': FieldValue.serverTimestamp(),
      'referredFirstClaimAt': FieldValue.serverTimestamp(),
    });
    await addCoins(
      uid: referredBy,
      amount: referral.referrerReward,
      reason: 'Referral bonus (${map['email'] ?? uid})',
    );
    await addCoins(
      uid: uid,
      amount: referral.referredReward,
      reason: 'Welcome referral bonus',
    );

    await createNotification(
      NotificationModel.newDraft(
        userUid: referredBy,
        type: NotifType.referralReward,
        title: 'Referral reward received',
        body:
            '+${referral.referrerReward} coins — your friend just made their first claim.',
        targetRoute: 'wallet',
      ),
    );
    await createNotification(
      NotificationModel.newDraft(
        userUid: uid,
        type: NotifType.referralReward,
        title: 'Welcome bonus unlocked',
        body: '+${referral.referredReward} coins from your referral.',
        targetRoute: 'wallet',
      ),
    );
  }

  // ---------- NOTIFICATIONS ----------

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  Future<String> createNotification(NotificationModel n) async {
    final ref = await _notifications.add(n.toMap());
    return ref.id;
  }

  Stream<List<NotificationModel>> streamMyNotifications(
    String userUid, {
    int limit = 50,
  }) {
    return _notifications
        .where('userUid', isEqualTo: userUid)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => NotificationModel.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) {
        final ad = a.createdAt ?? DateTime(2000);
        final bd = b.createdAt ?? DateTime(2000);
        return bd.compareTo(ad);
      });
      return list;
    });
  }

  Stream<int> streamUnreadNotificationCount(String userUid) {
    return _notifications
        .where('userUid', isEqualTo: userUid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markNotificationRead(String id) async {
    await _notifications.doc(id).update({'read': true});
  }

  Future<void> markAllNotificationsRead(String userUid) async {
    final snap = await _notifications
        .where('userUid', isEqualTo: userUid)
        .where('read', isEqualTo: false)
        .limit(100)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  // ---------- SAVED OFFERS & BUSINESSES ----------

  CollectionReference<Map<String, dynamic>> get _savedOffers =>
      _db.collection('saved_offers');

  CollectionReference<Map<String, dynamic>> get _savedBusinesses =>
      _db.collection('saved_businesses');

  String _savedOfferId(String uid, String offerId) => '${uid}_$offerId';
  String _savedBizId(String uid, String businessId) =>
      '${uid}_$businessId';

  Future<bool> isOfferSaved(String uid, String offerId) async {
    final snap =
        await _savedOffers.doc(_savedOfferId(uid, offerId)).get();
    return snap.exists;
  }

  Future<void> toggleSaveOffer({
    required String uid,
    required String offerId,
  }) async {
    final doc = _savedOffers.doc(_savedOfferId(uid, offerId));
    final existing = await doc.get();
    if (existing.exists) {
      await doc.delete();
    } else {
      await doc.set({
        'userUid': uid,
        'offerId': offerId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> isBusinessSaved(String uid, String businessId) async {
    final snap =
        await _savedBusinesses.doc(_savedBizId(uid, businessId)).get();
    return snap.exists;
  }

  Future<void> toggleSaveBusiness({
    required String uid,
    required String businessId,
  }) async {
    final doc = _savedBusinesses.doc(_savedBizId(uid, businessId));
    final existing = await doc.get();
    if (existing.exists) {
      await doc.delete();
    } else {
      await doc.set({
        'userUid': uid,
        'businessId': businessId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<OfferModel>> streamMySavedOffers(String uid) {
    return _savedOffers
        .where('userUid', isEqualTo: uid)
        .limit(50)
        .snapshots()
        .asyncMap((snap) async {
      final ids = snap.docs
          .map((d) => (d.data()['offerId'] ?? '') as String)
          .where((s) => s.isNotEmpty)
          .toList();
      final results = <OfferModel>[];
      for (final id in ids) {
        final o = await getOffer(id);
        if (o != null) results.add(o);
      }
      return results;
    });
  }

  Stream<List<BusinessModel>> streamMySavedBusinesses(String uid) {
    return _savedBusinesses
        .where('userUid', isEqualTo: uid)
        .limit(50)
        .snapshots()
        .asyncMap((snap) async {
      final ids = snap.docs
          .map((d) => (d.data()['businessId'] ?? '') as String)
          .where((s) => s.isNotEmpty)
          .toList();
      final results = <BusinessModel>[];
      for (final id in ids) {
        final b = await getBusiness(id);
        if (b != null) results.add(b);
      }
      return results;
    });
  }
}