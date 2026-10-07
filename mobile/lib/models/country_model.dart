import 'package:cloud_firestore/cloud_firestore.dart';

/// Country data (Firestore: countries/{code}).
class CountryModel {
  const CountryModel({
    required this.code,
    required this.name,
    required this.flag,
    this.currency = 'QAR',
    this.locale = 'en',
    this.order = 0,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final String code; // ISO code: QA, IN, AE
  final String name; // "Qatar"
  final String flag; // "🇶🇦"
  final String currency;
  final String locale;
  final int order;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CountryModel.fromMap(String code, Map<String, dynamic> map) {
    return CountryModel(
      code: code,
      name: (map['name'] ?? '') as String,
      flag: (map['flag'] ?? '') as String,
      currency: (map['currency'] ?? 'QAR') as String,
      locale: (map['locale'] ?? 'en') as String,
      order: (map['order'] ?? 0) as int,
      active: (map['active'] ?? true) as bool,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'flag': flag,
      'currency': currency,
      'locale': locale,
      'order': order,
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  CountryModel copyWith({
    String? name,
    String? flag,
    String? currency,
    String? locale,
    int? order,
    bool? active,
  }) {
    return CountryModel(
      code: code,
      name: name ?? this.name,
      flag: flag ?? this.flag,
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      order: order ?? this.order,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}