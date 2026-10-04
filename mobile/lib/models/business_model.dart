import 'package:cloud_firestore/cloud_firestore.dart';

/// Business data (Firestore: businesses/{id}).
class BusinessModel {
  const BusinessModel({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.category,
    required this.addressLine,
    required this.city,
    required this.country,
    required this.currency,
    this.description,
    this.phone,
    this.whatsapp,
    this.lat,
    this.lng,
    this.logoUrl,
    this.coverUrl,
    this.photos = const [],
    this.openTime = '09:00',
    this.closeTime = '23:00',
    this.website,
    this.mapUrl,
    this.status = 'pending',
    this.verified = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String name;
  final String category;
  final String addressLine;
  final String city;
  final String country;
  final String currency;
  final String? description;
  final String? phone;
  final String? whatsapp;
  final double? lat;
  final double? lng;
  final String? logoUrl;
  final String? coverUrl;
  final List<String> photos;

  /// Business hours in "HH:mm" format（24-hour）.
  final String openTime;
  final String closeTime;

  final String? website;
  final String? mapUrl;

  final String status; // pending | approved | rejected | suspended
  final bool verified;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Is the business open right now based on current time?
  bool get isOpenNow {
    try {
      final now = DateTime.now();
      final open = _parseTime(openTime);
      final close = _parseTime(closeTime);
      final minutes = now.hour * 60 + now.minute;
      final openMin = open.$1 * 60 + open.$2;
      final closeMin = close.$1 * 60 + close.$2;

      // Same-day range
      if (closeMin > openMin) {
        return minutes >= openMin && minutes < closeMin;
      }
      // Overnight range（e.g. 18:00 → 02:00）
      return minutes >= openMin || minutes < closeMin;
    } catch (_) {
      return true;
    }
  }

  String get hoursLabel => '$openTime – $closeTime';

  static (int, int) _parseTime(String t) {
    final parts = t.split(':');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }

  factory BusinessModel.newDraft({
    required String ownerUid,
    required String name,
    required String category,
    required String addressLine,
    String city = 'Doha',
    String country = 'QA',
    String currency = 'QAR',
    String? description,
    String? phone,
    String? whatsapp,
    String openTime = '09:00',
    String closeTime = '23:00',
    String? mapUrl,
  }) {
    return BusinessModel(
      id: '',
      ownerUid: ownerUid,
      name: name,
      category: category,
      addressLine: addressLine,
      city: city,
      country: country,
      currency: currency,
      description: description,
      phone: phone,
      whatsapp: whatsapp,
      openTime: openTime,
      closeTime: closeTime,
      mapUrl: mapUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory BusinessModel.fromMap(String id, Map<String, dynamic> map) {
    return BusinessModel(
      id: id,
      ownerUid: (map['ownerUid'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      category: (map['category'] ?? '') as String,
      addressLine: (map['addressLine'] ?? '') as String,
      city: (map['city'] ?? 'Doha') as String,
      country: (map['country'] ?? 'QA') as String,
      currency: (map['currency'] ?? 'QAR') as String,
      description: map['description'] as String?,
      phone: map['phone'] as String?,
      whatsapp: map['whatsapp'] as String?,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      logoUrl: map['logoUrl'] as String?,
      coverUrl: map['coverUrl'] as String?,
      photos:
          List<String>.from((map['photos'] as List?) ?? const []),
      openTime: (map['openTime'] ?? '09:00') as String,
      closeTime: (map['closeTime'] ?? '23:00') as String,
      website: map['website'] as String?,
      mapUrl: map['mapUrl'] as String?,
      status: (map['status'] ?? 'pending') as String,
      verified: (map['verified'] ?? false) as bool,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUid': ownerUid,
      'name': name,
      'category': category,
      'addressLine': addressLine,
      'city': city,
      'country': country,
      'currency': currency,
      'description': description,
      'phone': phone,
      'whatsapp': whatsapp,
      'lat': lat,
      'lng': lng,
      'logoUrl': logoUrl,
      'coverUrl': coverUrl,
      'photos': photos,
      'openTime': openTime,
      'closeTime': closeTime,
      'website': website,
      'mapUrl': mapUrl,
      'status': status,
      'verified': verified,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}