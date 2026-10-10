import 'package:cloud_firestore/cloud_firestore.dart';

/// Country data (Firestore: countries/{code}).
class CountryModel {
  const CountryModel({
    required this.code,
    required this.name,
    this.nameAr = '',
    required this.flag,
    this.currency = 'QAR',
    this.dialCode = '',
    this.locale = 'en',
    this.locales = const ['en'],
    this.rtl = false,
    this.timezone = '',
    this.dateFormat = 'DD/MM/YYYY',
    this.order = 0,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final String code; // ISO code: QA, IN, AE
  final String name; // "Qatar"
  final String nameAr; // "قطر"
  final String flag; // "🇶🇦"
  final String currency; // "QAR", "AED", "SAR", "KWD", "BHD", "OMR", "INR"
  final String dialCode; // "+974", "+971"
  final String locale; // default locale: 'en' or 'ar'
  final List<String> locales; // supported: ['en', 'ar']
  final bool rtl; // right-to-left layout
  final String timezone; // "Asia/Qatar"
  final String dateFormat; // "DD/MM/YYYY"
  final int order;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CountryModel.fromMap(String code, Map<String, dynamic> map) {
    return CountryModel(
      code: code,
      name: (map['name'] ?? '') as String,
      nameAr: (map['nameAr'] ?? '') as String,
      flag: (map['flag'] ?? '') as String,
      currency: (map['currency'] ?? 'QAR') as String,
      dialCode: (map['dialCode'] ?? '') as String,
      locale: (map['locale'] ?? 'en') as String,
      locales: (map['locales'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['en'],
      rtl: (map['rtl'] ?? false) as bool,
      timezone: (map['timezone'] ?? '') as String,
      dateFormat: (map['dateFormat'] ?? 'DD/MM/YYYY') as String,
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
      'nameAr': nameAr,
      'flag': flag,
      'currency': currency,
      'dialCode': dialCode,
      'locale': locale,
      'locales': locales,
      'rtl': rtl,
      'timezone': timezone,
      'dateFormat': dateFormat,
      'order': order,
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  CountryModel copyWith({
    String? name,
    String? nameAr,
    String? flag,
    String? currency,
    String? dialCode,
    String? locale,
    List<String>? locales,
    bool? rtl,
    String? timezone,
    String? dateFormat,
    int? order,
    bool? active,
  }) {
    return CountryModel(
      code: code,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      flag: flag ?? this.flag,
      currency: currency ?? this.currency,
      dialCode: dialCode ?? this.dialCode,
      locale: locale ?? this.locale,
      locales: locales ?? this.locales,
      rtl: rtl ?? this.rtl,
      timezone: timezone ?? this.timezone,
      dateFormat: dateFormat ?? this.dateFormat,
      order: order ?? this.order,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if Arabic is a supported locale.
  bool get supportsArabic => locales.contains('ar');

  /// Get localized country name based on locale.
  String localizedName(String locale) {
    if (locale == 'ar' && nameAr.isNotEmpty) return nameAr;
    return name;
  }
}