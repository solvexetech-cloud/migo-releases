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
    this.status = 'pending', // pending | approved | rejected | suspended
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
  final String status;
  final bool verified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
      'status': status,
      'verified': verified,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  BusinessModel copyWith({
    String? name,
    String? category,
    String? addressLine,
    String? city,
    String? country,
    String? currency,
    String? description,
    String? phone,
    String? whatsapp,
    String? status,
    bool? verified,
    String? logoUrl,
    String? coverUrl,
  }) {
    return BusinessModel(
      id: id,
      ownerUid: ownerUid,
      name: name ?? this.name,
      category: category ?? this.category,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      country: country ?? this.country,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      lat: lat,
      lng: lng,
      logoUrl: logoUrl ?? this.logoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      status: status ?? this.status,
      verified: verified ?? this.verified,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}