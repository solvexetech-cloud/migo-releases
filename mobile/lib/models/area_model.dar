import 'package:cloud_firestore/cloud_firestore.dart';

/// Area data (Firestore: areas/{slug}).
///
/// Areas are neighborhoods inside a zone:
/// - Doha Metro → The Pearl, West Bay, Lusail
/// - Ernakulam → Kakkanad, Edappally, Fort Kochi
class AreaModel {
  const AreaModel({
    required this.id,
    required this.zoneSlug,
    required this.name,
    required this.slug,
    this.agencyUid,
    this.order = 0,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String zoneSlug;
  final String name;
  final String slug;
  final String? agencyUid; // assigned agency (null if none)
  final int order;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasAgency => agencyUid != null && agencyUid!.isNotEmpty;

  factory AreaModel.fromMap(String id, Map<String, dynamic> map) {
    return AreaModel(
      id: id,
      zoneSlug: (map['zoneSlug'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      slug: (map['slug'] ?? id) as String,
      agencyUid: map['agencyUid'] as String?,
      order: (map['order'] ?? 0) as int,
      active: (map['active'] ?? true) as bool,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'zoneSlug': zoneSlug,
      'name': name,
      'slug': slug,
      'agencyUid': agencyUid,
      'order': order,
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AreaModel copyWith({
    String? name,
    String? agencyUid,
    int? order,
    bool? active,
  }) {
    return AreaModel(
      id: id,
      zoneSlug: zoneSlug,
      name: name ?? this.name,
      slug: slug,
      agencyUid: agencyUid ?? this.agencyUid,
      order: order ?? this.order,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}