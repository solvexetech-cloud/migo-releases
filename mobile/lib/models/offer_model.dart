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
    required this.titleEn,
    required this.titleAr,
    required this.description,
    required this.descriptionEn,
    required this.descriptionAr,
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
    this.reserveEnabled = false,
    this.reserveTotalSlots = 0,
    this.reserveBookedSlots = 0,
    this.reserveHoldHours = 6,
    this.reserveTokenRequired = false,
    this.reserveMaxPerCustomer = 1,
    this.status = 'pending',
    this.isPromoted = false,
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
  final String titleEn;
  final String titleAr;
  final String description;
  final String descriptionEn;
  final String descriptionAr;
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
  final bool reserveEnabled;
  final int reserveTotalSlots;
  final int reserveBookedSlots;
  final int reserveHoldHours;
  final bool reserveTokenRequired;
  final int reserveMaxPerCustomer;
  final String status;
  final bool isPromoted;

  // ---------- B3 GEOGRAPHY ----------
  final String? countryCode;
  final String? zoneId;
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
    String? titleEn,
    String? titleAr,
    required String description,
    String? descriptionEn,
    String? descriptionAr,
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
    String? countryCode,
    String? zoneId,
    String? areaId,
  }) {
    final now = DateTime.now();
    final tEn = titleEn ?? title;
    final tAr = titleAr ?? title;
    final dEn = descriptionEn ?? description;
    final dAr = descriptionAr ?? description;
    return OfferModel(
      id: '',
      businessId: businessId,
      businessName: businessName,
      title: title,
      titleEn: tEn,
      titleAr: tAr,
      description: description,
      descriptionEn: dEn,
      descriptionAr: dAr,
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
    final baseTitle = (map['title'] ?? '') as String;
    final baseDesc = (map['description'] ?? '') as String;
    return OfferModel(
      id: id,
      businessId: (map['businessId'] ?? '') as String,
      businessName: (map['businessName'] ?? '') as String,
      title: baseTitle,
      titleEn: (map['titleEn'] ?? baseTitle) as String,
      titleAr: (map['titleAr'] ?? baseTitle) as String,
      description: baseDesc,
      descriptionEn: (map['descriptionEn'] ?? baseDesc) as String,
      descriptionAr: (map['descriptionAr'] ?? baseDesc) as String,
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
      reserveEnabled: (map['reserve'] as Map<String, dynamic>?)?['enabled'] as bool? ?? false,
      reserveTotalSlots: ((map['reserve'] as Map<String, dynamic>?)?['totalSlots'] as num?)?.toInt() ?? (map['totalSlots'] as num?)?.toInt() ?? 0,
      reserveBookedSlots: (map['bookedSlots'] as num?)?.toInt() ?? 0,
      reserveHoldHours: ((map['reserve'] as Map<String, dynamic>?)?['holdHours'] as num?)?.toInt() ?? 6,
      reserveTokenRequired: (map['reserve'] as Map<String, dynamic>?)?['tokenRequired'] as bool? ?? false,
      reserveMaxPerCustomer: ((map['reserve'] as Map<String, dynamic>?)?['maxPerCustomer'] as num?)?.toInt() ?? 1,
      status: (map['status'] ?? 'pending') as String,
      isPromoted: (map['isPromoted'] ?? false) as bool,
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
      'titleEn': titleEn,
      'titleAr': titleAr,
      'description': description,
      'descriptionEn': descriptionEn,
      'descriptionAr': descriptionAr,
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
      'isPromoted': isPromoted,
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
    bool? isPromoted,
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
      titleEn: titleEn,
      titleAr: titleAr,
      description: description,
      descriptionEn: descriptionEn,
      descriptionAr: descriptionAr,
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
      isPromoted: isPromoted ?? this.isPromoted,
      countryCode: countryCode ?? this.countryCode,
      zoneId: zoneId ?? this.zoneId,
      areaId: areaId ?? this.areaId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}