import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

/// Central auth service. All signup/login/logout calls go through here.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up a new user with email + password.
  /// Also creates a MIGO user document in Firestore.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = cred.user;
    if (user != null) {
      await FirestoreService.instance.createUser(
        UserModel.fresh(
          uid: user.uid,
          email: user.email ?? email.trim(),
          displayName: displayName,
        ),
      );
    }
    return cred;
  }

  /// Sign in an existing user. Ensures a Firestore doc exists.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = cred.user;
    if (user != null) {
      final existing = await FirestoreService.instance.getUser(user.uid);
      if (existing == null) {
        // Legacy user from before Firestore was enabled — backfill.
        await FirestoreService.instance.createUser(
          UserModel.fresh(
            uid: user.uid,
            email: user.email ?? email.trim(),
          ),
        );
      }
    }
    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Human-readable error message from FirebaseAuthException.
  String describeError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Check your internet connection.';
        default:
          return error.message ?? 'Something went wrong.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}