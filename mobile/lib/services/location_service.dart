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

  Future<AreaModel?> getDefaultArea(UserModel? user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAreaId = prefs.getString('selected_area_id');

      if (savedAreaId != null && savedAreaId.isNotEmpty) {
         final doc = await _db.collection('areas').doc(savedAreaId).get();
         if (doc.exists) return AreaModel.fromMap(doc.id, doc.data()!);
         final zoneDoc = await _db.collection('zones').doc(savedAreaId).get();
         if (zoneDoc.exists) {
            final data = zoneDoc.data()!;
            return AreaModel(id: zoneDoc.id, zoneSlug: zoneDoc.id, name: data['name'] ?? 'Unknown', slug: zoneDoc.id);
         }
      }

      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
            final lat = position.latitude;
            final lng = position.longitude;
            
            String detectedCountry = 'QA';
            if (lat > 22 && lat < 27 && lng > 50 && lng < 52) detectedCountry = 'QA';
            else if (lat > 22 && lat < 27 && lng > 54 && lng < 57) detectedCountry = 'AE';
            else if (lat > 23 && lat < 32 && lng > 34 && lng < 56) detectedCountry = 'SA';
            else if (lat > 28 && lat < 31 && lng > 46 && lng < 49) detectedCountry = 'KW';
            else if (lat > 16 && lat < 26 && lng > 51 && lng < 60) detectedCountry = 'OM';
            else if (lat > 22 && lat < 33 && lng > 24 && lng < 36) detectedCountry = 'EG';
            else if (lat > 8 && lat < 37 && lng > 68 && lng < 97) detectedCountry = 'IN';
            else if (lat > 24 && lat < 27 && lng > 50 && lng < 51) detectedCountry = 'BH';

            // Index ആവശ്യമില്ലാതെ, countryCode മാത്രം ഉപയോഗിച്ച് എടുക്കാം
            final zoneQuery = await _db.collection('zones')
                .where('countryCode', isEqualTo: detectedCountry)
                .limit(1)
                .get();
            if (zoneQuery.docs.isNotEmpty) {
              final zoneData = zoneQuery.docs.first.data();
              return AreaModel(
                id: zoneQuery.docs.first.id,
                zoneSlug: zoneQuery.docs.first.id,
                name: zoneData['name'] ?? 'Doha',
                slug: zoneQuery.docs.first.id,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Geolocation error: $e');
      }

      // Index ആവശ്യമില്ലാത്ത ഡീഫോൾട്ട് ഖത്തർ (Doha)
      final qatarQuery = await _db.collection('zones')
          .where('countryCode', isEqualTo: 'QA')
          .limit(1)
          .get();
      if (qatarQuery.docs.isNotEmpty) {
         final qData = qatarQuery.docs.first.data();
         return AreaModel(
           id: qatarQuery.docs.first.id,
           zoneSlug: qatarQuery.docs.first.id,
           name: qData['name'] ?? 'Doha',
           slug: qatarQuery.docs.first.id,
         );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting default area: $e');
      return null;
    }
  }

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