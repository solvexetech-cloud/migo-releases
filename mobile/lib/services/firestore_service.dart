import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business_model.dart';
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

  /// Create a new business. Returns the new document ID.
  Future<String> createBusiness(BusinessModel business) async {
    final ref = await _businesses.add(business.toMap());
    return ref.id;
  }

  Future<BusinessModel?> getBusiness(String id) async {
    final snap = await _businesses.doc(id).get();
    if (!snap.exists || snap.data() == null) return null;
    return BusinessModel.fromMap(id, snap.data()!);
  }

  /// Stream the current owner's business（one per owner for now）.
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

  Future<void> updateBusiness(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _businesses.doc(id).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}