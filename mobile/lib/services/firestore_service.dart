import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// All Firestore reads/writes for MIGO go through here.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- USERS ----------

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Create a user document. Called right after Firebase signup.
  Future<void> createUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  /// Fetch a user document by uid. Returns null if it does not exist.
  Future<UserModel?> getUser(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserModel.fromMap(uid, snap.data()!);
  }

  /// Stream a user document（auto-refreshes when data changes）.
  Stream<UserModel?> streamUser(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserModel.fromMap(uid, snap.data()!);
    });
  }

  /// Update a subset of user fields.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Add coins to a user and log a coin transaction.
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
}