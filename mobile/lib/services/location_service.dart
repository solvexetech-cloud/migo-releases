import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/area_model.dart';
import '../models/user_model.dart';

class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. ലൊക്കേഷൻ എടുത്ത് ഫയർസ്റ്റോറിൽ സേവ് ചെയ്യാൻ
  Future<void> updateUserLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _db.collection('users').doc(user.uid).update({
        'location': GeoPoint(position.latitude, position.longitude),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });

      debugPrint('Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  // 2. യൂസറുടെ ഏരിയ (Area) കണ്ടെത്താൻ -> AreaModel റിട്ടേൺ ചെയ്യുന്നു
  Future<AreaModel?> getDefaultArea(UserModel? user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAreaId = prefs.getString('selected_area_id');
      
      // ലോക്കൽ സ്റ്റോറേജിൽ ഉണ്ടെങ്കിൽ അത് എടുക്കാം
      if (savedAreaId != null && savedAreaId.isNotEmpty) {
         final doc = await _db.collection('areas').doc(savedAreaId).get();
         if (doc.exists) return AreaModel.fromMap(doc.id, doc.data()!);
      }

      // യൂസർ പ്രൊഫൈലിൽ ഉണ്ടെങ്കിൽ അത് എടുക്കാം (നേരിട്ട് ഫയർസ്റ്റോറിൽ നിന്ന്)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await _db.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null && data['areaId'] != null) {
            final String areaId = data['areaId'];
            if (areaId.isNotEmpty) {
              final doc = await _db.collection('areas').doc(areaId).get();
              if (doc.exists) return AreaModel.fromMap(doc.id, doc.data()!);
            }
          }
        }
      }
      
      // ഒന്നും കണ്ടെത്തിയില്ലെങ്കിൽ ആദ്യത്തെ ഏരിയ എടുക്കാം
      final query = await _db.collection('areas').limit(1).get();
      if (query.docs.isNotEmpty) {
         return AreaModel.fromMap(query.docs.first.id, query.docs.first.data());
      }
      return null;
    } catch (e) {
      debugPrint('Error getting default area: $e');
      return null;
    }
  }

  // 3. യൂസർ ഏരിയ സെലക്ട് ചെയ്യുമ്പോൾ സേവ് ചെയ്യാൻ
  Future<void> saveSelectedArea({
    required String uid,
    required String areaId,
    required String countryCode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_area_id', areaId);

      await _db.collection('users').doc(uid).update({
        'areaId': areaId,
        'country': countryCode,
      });
    } catch (e) {
      debugPrint('Error saving area: $e');
    }
  }
}