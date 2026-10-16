import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// PHASE I — Business Auth Service
/// Handles login/logout for business owners
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════
  // SIGN IN
  // ═══════════════════════════════════════════════════
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Firebase Auth sign in
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user!.uid;

      // 2. Check user doc + role
      final userDoc = await _db.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return {'success': false, 'error': 'User profile not found'};
      }

      final data = userDoc.data()!;
      final role = data['role'] as String?;

      // 3. Allow only 'business' role
      if (role != 'business') {
        await _auth.signOut();
        return {
          'success': false,
          'error': 'Access denied. Business accounts only.',
        };
      }

      return {
        'success': true,
        'uid': uid,
        'businessId': data['businessId'],
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _authError(e.code),
      };
    } catch (e) {
      return {'success': false, 'error': 'Login failed: $e'};
    }
  }

  // ═══════════════════════════════════════════════════
  // SIGN OUT
  // ═══════════════════════════════════════════════════
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ═══════════════════════════════════════════════════
  // CURRENT USER
  // ═══════════════════════════════════════════════════
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authState => _auth.authStateChanges();

  // ═══════════════════════════════════════════════════
  // ERROR MESSAGES
  // ═══════════════════════════════════════════════════
  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'invalid-credential':
        return 'Invalid email or password';
      default:
        return 'Login failed. Please try again';
    }
  }
}