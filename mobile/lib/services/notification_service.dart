import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

/// Handles FCM push notifications: permission, token, listeners.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// VAPID key for Web Push (from Firebase Console → Cloud Messaging).
  static const String _webVapidKey =
      'BHDmhktlvvoDJoFTJYBGmTMNZiTz9zZxI3aZ2MORCzwdpzJ8Snxbu3oPzyL_lgTuvmtcDma9zA3qxQ3E-PsvWc8';

  /// Call once after login (or on app start if signed in).
  Future<void> init() async {
    try {
      // 1. Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM: Notification permission denied');
        return;
      }

            // 2. Get token (web needs VAPID key)
      //    On web: SW is registered manually in index.html.
      //    The auto-register call may warn, but token still works.
      String? token;
      try {
        token = kIsWeb
            ? await _messaging.getToken(vapidKey: _webVapidKey)
            : await _messaging.getToken();
      } catch (e) {
        debugPrint('FCM getToken error (non-fatal): $e');
      }

      if (token == null) {
        debugPrint('FCM: Could not get token');
        return;
      }

      debugPrint('FCM: Token = $token');
      await _saveTokenToFirestore(token);

      // 3. Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM: Token refreshed = $newToken');
        await _saveTokenToFirestore(newToken);
      });

      // 4. Foreground messages (app is open)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground: ${message.notification?.title}');
        // You can show an in-app banner/snackbar here if you want.
      });

      // 5. When user taps a notification (app was background/closed)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Opened: ${message.notification?.title}');
        // Navigation on tap could be added here later.
      });
    } catch (e) {
      debugPrint('FCM init error: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'fcmPlatform': kIsWeb ? 'web' : 'mobile',
        },
        SetOptions(merge: true),
      );
      debugPrint('FCM: Token saved to Firestore');
    } catch (e) {
      debugPrint('FCM: Save token error: $e');
    }
  }

  /// Call on logout to clean up.
  Future<void> clearToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set(
        {
          'fcmToken': null,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('FCM clearToken error: $e');
    }
  }
}