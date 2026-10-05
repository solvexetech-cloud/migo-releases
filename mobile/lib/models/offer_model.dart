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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get savings => originalPrice - offerPrice;
  int get percentOff => originalPrice > 0
      ? (((originalPrice - offerPrice) / originalPrice) * 100).round()
      : 0;

  // കാലഹരണപ്പെട്ടോ എന്ന് പരിശോധിക്കാൻ
  bool get isExpired => endAt.isBefore(DateTime.now());

  // ഓഫർ ഇപ്പോൾ സജീവമാണോ എന്ന് പരിശോധിക്കാൻ
  bool get isActiveNow {
    final now = DateTime.now();
    return status == 'live' &&
        startAt.isBefore(now) &&
        endAt.isAfter(now);
  }

  // എത്ര ദിവസം ബാക്കിയുണ്ട്
  int get daysRemaining {
    final diff = endAt.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

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
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}