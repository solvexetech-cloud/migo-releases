import 'package:cloud_firestore/cloud_firestore.dart';

/// Zone data (Firestore: zones/{slug}).
///
/// Zones are major regions inside a country:
/// - Qatar: Doha Metro, Al Wakrah, Al Khor
/// - India: Ernakulam, Thrissur, Kozhikode (districts)
class ZoneModel {
  const ZoneModel({
    required this.id,
    required this.countryCode,
    required this.name,
    required this.slug,
    this.order = 0,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id; // doc ID (= slug)
  final String countryCode;
  final String name;
  final String slug;
  final int order;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ZoneModel.fromMap(String id, Map<String, dynamic> map) {
    return ZoneModel(
      id: id,
      countryCode: (map['countryCode'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      slug: (map['slug'] ?? id) as String,
      order: (map['order'] ?? 0) as int,
      active: (map['active'] ?? true) as bool,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'countryCode': countryCode,
      'name': name,
      'slug': slug,
      'order': order,
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}