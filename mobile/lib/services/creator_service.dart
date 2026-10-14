import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/creator_model.dart';

/// PHASE E — E6: Creator/Vlogger service
class CreatorService {
  CreatorService._();
  static final CreatorService instance = CreatorService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _creators =>
      _db.collection('creators');

  /// Generate unique creator referral code
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return 'CR_${List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join()}';
  }

  /// Check if user is already a creator
  Future<bool> isCreator(String uid) async {
    try {
      final doc = await _creators.doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get creator by uid
  Future<CreatorModel?> getCreator(String uid) async {
    try {
      final doc = await _creators.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return CreatorModel.fromMap(uid, doc.data()!);
    } catch (e) {
      return null;
    }
  }

  /// Get creator by referral code
  Future<CreatorModel?> getCreatorByCode(String code) async {
    try {
      final snap = await _creators
          .where('referralCode', isEqualTo: code.toUpperCase())
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return CreatorModel.fromMap(snap.docs.first.id, snap.docs.first.data());
    } catch (e) {
      return null;
    }
  }

  /// Stream creator data
  Stream<CreatorModel?> streamCreator(String uid) {
    return _creators.doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return CreatorModel.fromMap(uid, snap.data()!);
    });
  }

  /// Apply as creator
  Future<void> applyAsCreator({
    required String uid,
    required String displayName,
    required String email,
    required String bio,
    String? channelUrl,
    String category = 'general',
    int followers = 0,
  }) async {
    final existing = await _creators.doc(uid).get();
    if (existing.exists) {
      throw Exception('You already have a creator application');
    }

    final code = _generateCode();
    final creator = CreatorModel(
      uid: uid,
      displayName: displayName,
      email: email,
      bio: bio,
      channelUrl: channelUrl,
      category: category,
      followers: followers,
      referralCode: code,
      status: CreatorStatus.pending,
      createdAt: DateTime.now(),
    );

    await _creators.doc(uid).set(creator.toMap());
  }

  /// Stream my creator profile
  Stream<CreatorModel?> streamMyCreator(String uid) {
    return _creators.doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return CreatorModel.fromMap(uid, snap.data()!);
    });
  }

  /// Update creator profile
  Future<void> updateCreator(String uid, Map<String, dynamic> data) async {
    await _creators.doc(uid).set(
      {...data, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}