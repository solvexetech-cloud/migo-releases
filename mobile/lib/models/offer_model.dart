import 'package:cloud_firestore/cloud_firestore.dart';

/// Offer types supported by MIGO.
enum OfferType {
  standard,
  flash,
  group,
  hidden,
  birthday,
}

extension OfferTypeX on OfferType {
  String get id => name;
  String get label {
    switch (this) {
      case OfferType.standard:
        return 'Standard Deal';
      case OfferType.flash:
        return 'Flash Deal';
      case OfferType.group:
        return 'Group Deal';
      case OfferType.hidden:
        return 'Hidden Gem';
      case OfferType.birthday:
        return 'Birthday Deal';
    }
  }
}

OfferType offerTypeFromString(String? s) {
  switch (s) {
    case 'flash':
      return OfferType.flash;
    case 'group':
      return OfferType.group;
    case 'hidden':
      return OfferType.hidden;
    case 'birthday':
      return OfferType.birthday;
    default:
      return OfferType.standard;
  }
}

/// Offer data (Firestore: offers/{id}).
class OfferModel {
  const OfferModel({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.title,
    required this.description,
    required this.originalPrice,
    required this.offerPrice,
    required this.currency,
    required this.type,
    required this.startAt,
    required this.endAt,
    this.category = 'Food',
    this.imageUrl,
    this.terms,
    this.dailyLimit,
    this.totalLimit,
    this.claimedCount = 0,
    this.status = 'pending', // pending | live | paused | expired
    // B3 Geography (denormalized from business for fast filtering)
    this.countryCode,
    this.zoneId,
    this.areaId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String businessName;
  final String title;
  final String description;
  final double originalPrice;
  final double offerPrice;
  final String currency;
  final OfferType type;
  final DateTime startAt;
  final DateTime endAt;
  final String category;
  final String? imageUrl;
  final String? terms;
  final int? dailyLimit;
  final int? totalLimit;
  final int claimedCount;
  final String status;

  // ---------- B3 GEOGRAPHY ----------
  /// Country code (QA, IN, AE)
  final String? countryCode;

  /// Zone slug (doha-metro, ernakulam)
  final String? zoneId;

  /// Area slug (the-pearl, kakkanad)
  final String? areaId;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get savings => originalPrice - offerPrice;
  int get percentOff => originalPrice > 0
      ? (((originalPrice - offerPrice) / originalPrice) * 100).round()
      : 0;

  bool get isExpired => endAt.isBefore(DateTime.now());

  bool get isActiveNow {
    final now = DateTime.now();
    return status == 'live' &&
        startAt.isBefore(now) &&
        endAt.isAfter(now);
  }

  int get daysRemaining {
    final diff = endAt.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Does this offer have geography assigned?
  bool get hasGeography =>
      countryCode != null &&
      countryCode!.isNotEmpty &&
      zoneId != null &&
      zoneId!.isNotEmpty &&
      areaId != null &&
      areaId!.isNotEmpty;

  factory OfferModel.newDraft({
    required String businessId,
    required String businessName,
    required String title,
    required String description,
    required double originalPrice,
    required double offerPrice,
    required String currency,
    required OfferType type,
    required DateTime startAt,
    required DateTime endAt,
    String category = 'Food',
    String? terms,
    int? dailyLimit,
    int? totalLimit,
    // B3 geography
    String? countryCode,
    String? zoneId,
    String? areaId,
  }) {
    final now = DateTime.now();
    return OfferModel(
      id: '',
      businessId: businessId,
      businessName: businessName,
      title: title,
      description: description,
      originalPrice: originalPrice,
      offerPrice: offerPrice,
      currency: currency,
      type: type,
      startAt: startAt,
      endAt: endAt,
      category: category,
      terms: terms,
      dailyLimit: dailyLimit,
      totalLimit: totalLimit,
      countryCode: countryCode,
      zoneId: zoneId,
      areaId: areaId,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory OfferModel.fromMap(String id, Map<String, dynamic> map) {
    return OfferModel(
      id: id,
      businessId: (map['businessId'] ?? '') as String,
      businessName: (map['businessName'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      originalPrice: (map['originalPrice'] as num? ?? 0).toDouble(),
      offerPrice: (map['offerPrice'] as num? ?? 0).toDouble(),
      currency: (map['currency'] ?? 'QAR') as String,
      type: offerTypeFromString(map['type'] as String?),
      startAt: (map['startAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endAt: (map['endAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 7)),
      category: (map['category'] ?? 'Food') as String,
      imageUrl: map['imageUrl'] as String?,
      terms: map['terms'] as String?,
      dailyLimit: map['dailyLimit'] as int?,
      totalLimit: map['totalLimit'] as int?,
      claimedCount: (map['claimedCount'] ?? 0) as int,
      status: (map['status'] ?? 'pending') as String,
      // B3 geography
      countryCode: map['countryCode'] as String?,
      zoneId: map['zoneId'] as String?,
      areaId: map['areaId'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'businessName': businessName,
      'title': title,
      'description': description,
      'originalPrice': originalPrice,
      'offerPrice': offerPrice,
      'currency': currency,
      'type': type.id,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'category': category,
      'imageUrl': imageUrl,
      'terms': terms,
      'dailyLimit': dailyLimit,
      'totalLimit': totalLimit,
      'claimedCount': claimedCount,
      'status': status,
      // B3 geography
      'countryCode': countryCode,
      'zoneId': zoneId,
      'areaId': areaId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  OfferModel copyWith({
    String? imageUrl,
    String? status,
    int? claimedCount,
    String? terms,
    int? dailyLimit,
    int? totalLimit,
    String? countryCode,
    String? zoneId,
    String? areaId,
  }) {
    return OfferModel(
      id: id,
      businessId: businessId,
      businessName: businessName,
      title: title,
      description: description,
      originalPrice: originalPrice,
      offerPrice: offerPrice,
      currency: currency,
      type: type,
      startAt: startAt,
      endAt: endAt,
      category: category,
      imageUrl: imageUrl ?? this.imageUrl,
      terms: terms ?? this.terms,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      totalLimit: totalLimit ?? this.totalLimit,
      claimedCount: claimedCount ?? this.claimedCount,
      status: status ?? this.status,
      countryCode: countryCode ?? this.countryCode,
      zoneId: zoneId ?? this.zoneId,
      areaId: areaId ?? this.areaId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}