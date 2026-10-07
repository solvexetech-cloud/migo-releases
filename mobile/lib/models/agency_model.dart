import 'package:cloud_firestore/cloud_firestore.dart';

/// Agency data (Firestore: agencies/{id}).
///
/// An agency is a franchise partner who manages
/// a set of areas (via areaIds / area slugs).
class AgencyModel {
  const AgencyModel({
    required this.id,
    required this.ownerUid,
    required this.name,
    this.email,
    this.phone,
    this.areaIds = const [],
    this.countryCode = 'QA',
    this.zoneSlug,
    this.revenueShare = 0.40,
    this.status = 'active',
    this.contractStart,
    this.contractEnd,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String name;
  final String? email;
  final String? phone;
  final List<String> areaIds; // area slugs
  final String countryCode;
  final String? zoneSlug;
  final double revenueShare; // 0.0 - 1.0 (e.g. 0.40 = 40%)
  final String status; // active | suspended | pending
  final DateTime? contractStart;
  final DateTime? contractEnd;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == 'active';

  factory AgencyModel.fromMap(String id, Map<String, dynamic> map) {
    return AgencyModel(
      id: id,
      ownerUid: (map['ownerUid'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      areaIds: List<String>.from(map['areaIds'] ?? const []),
      countryCode: (map['countryCode'] ?? 'QA') as String,
      zoneSlug: map['zoneSlug'] as String?,
      revenueShare: ((map['revenueShare'] ?? 0.40) as num).toDouble(),
      status: (map['status'] ?? 'active') as String,
      contractStart: (map['contractStart'] as Timestamp?)?.toDate(),
      contractEnd: (map['contractEnd'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUid': ownerUid,
      'name': name,
      'email': email,
      'phone': phone,
      'areaIds': areaIds,
      'countryCode': countryCode,
      'zoneSlug': zoneSlug,
      'revenueShare': revenueShare,
      'status': status,
      'contractStart': contractStart != null
          ? Timestamp.fromDate(contractStart!)
          : null,
      'contractEnd': contractEnd != null
          ? Timestamp.fromDate(contractEnd!)
          : null,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}