import '../models/area_model.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

/// MIGO Location Service
///
/// Provides customer location defaults based on user profile.
/// - Detects user's default area from `city` field
/// - Falls back to country's first area
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Map of city name → default area slug.
  /// Update this map as new cities are onboarded.
  static const Map<String, String> _cityToArea = {
    // Qatar
    'doha': 'the-pearl',
    'the pearl': 'the-pearl',
    'west bay': 'west-bay',
    'lusail': 'lusail',
    'al wakrah': 'wakrah-city',
    'al khor': 'al-khor',
    'al rayyan': 'education-city',

    // Kerala
    'kochi': 'kakkanad',
    'cochin': 'kakkanad',
    'ernakulam': 'kakkanad',
    'kakkanad': 'kakkanad',
    'edappally': 'edappally',
    'thrissur': 'thrissur-city',
    'guruvayur': 'guruvayur',
    'kozhikode': 'kozhikode-city',
    'calicut': 'kozhikode-city',
    'thiruvananthapuram': 'technopark',
    'trivandrum': 'technopark',
  };

  /// Map of country code → default city name.
  static const Map<String, String> _countryDefaultCity = {
    'QA': 'Doha',
    'IN': 'Kochi',
  };

  /// Get default area for user (without Firestore write).
  ///
  /// Priority:
  /// 1. User's persisted `currentAreaId`
  /// 2. Map user's `city` → area slug
  /// 3. First active area of user's country
  /// 4. null (no default)
  Future<AreaModel?> getDefaultArea(UserModel? user) async {
    if (user == null) return null;

    // 1. Persisted selection
    if (user.currentAreaId != null && user.currentAreaId!.isNotEmpty) {
      final area = await FirestoreService.instance.getArea(
        user.currentAreaId!,
      );
      if (area != null && area.active) return area;
    }

    // 2. City → area mapping
    final city = (user.city).toLowerCase().trim();
    final areaSlug = _cityToArea[city];
    if (areaSlug != null) {
      final area = await FirestoreService.instance.getArea(areaSlug);
      if (area != null && area.active) return area;
    }

    // 3. First active area in user's country
    final countryCode = user.currentCountryCode ?? user.country;
    final countries = await FirestoreService.instance.getCountries();
    final country = countries.firstWhere(
      (c) => c.code == countryCode,
      orElse: () => countries.isNotEmpty ? countries.first : throw StateError('No countries'),
    );

    final zones =
        await FirestoreService.instance.getZonesByCountry(country.code);
    for (final zone in zones) {
      final areas =
          await FirestoreService.instance.getAreasByZone(zone.id);
      if (areas.isNotEmpty) return areas.first;
    }

    return null;
  }

  /// Persist user's selected area to their profile.
  Future<void> saveSelectedArea({
    required String uid,
    required String areaId,
    required String countryCode,
  }) async {
    await FirestoreService.instance.updateUser(uid, {
      'currentAreaId': areaId,
      'currentCountryCode': countryCode,
    });
  }

  /// Get city name for a country.
  String defaultCityForCountry(String countryCode) {
    return _countryDefaultCity[countryCode] ?? 'Doha';
  }
}