import 'package:cloud_firestore/cloud_firestore.dart';

/// PHASE I — Business Offer Model
class OfferModel {
  final String id;
  final String businessId;
  final String businessName;
  final String title;
  final String titleEn;
  final String titleAr;
  final String description;
  final String descriptionEn;
  final String descriptionAr;
  final String category;
  final String imageUrl;
  final double originalPrice;
  final double offerPrice;
  final String currency;
  final String type;
  final String status;
  final String areaId;
  final String? countryCode;
  final String? whatsappNumber;
  final String? orderLink;
  final DateTime? startDate;
  final DateTime? endDate;
  final int totalStock;
  final int claimedCount;
  final int bookedSlots;
  final bool reserveEnabled;
  final int maxPerCustomer;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OfferModel({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.title,
    required this.titleEn,
    required this.titleAr,
    required this.description,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.category,
    required this.imageUrl,
    required this.originalPrice,
    required this.offerPrice,
    required this.currency,
    required this.type,
    required this.status,
    required this.areaId,
    this.countryCode,
    this.whatsappNumber,
    this.orderLink,
    this.startDate,
    this.endDate,
    this.totalStock = 0,
    this.claimedCount = 0,
    this.bookedSlots = 0,
    this.reserveEnabled = false,
    this.maxPerCustomer = 1,
    this.createdAt,
    this.updatedAt,
  });

  double get savings => originalPrice - offerPrice;
  int get discountPercent =>
      originalPrice > 0 ? ((savings / originalPrice) * 100).round() : 0;
  bool get isActive => status == 'live' || status == 'approved';
  bool get isPending => status == 'pending';
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
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
      category: (map['category'] ?? '') as String,
      imageUrl: (map['imageUrl'] ?? '') as String,
      originalPrice: ((map['originalPrice'] ?? 0) as num).toDouble(),
      offerPrice: ((map['offerPrice'] ?? 0) as num).toDouble(),
      currency: (map['currency'] ?? 'QAR') as String,
      type: (map['type'] ?? 'standard') as String,
      status: (map['status'] ?? 'pending') as String,
      areaId: (map['areaId'] ?? '') as String,
      countryCode: map['countryCode'] as String?,
      whatsappNumber: map['whatsappNumber'] as String?,
      orderLink: map['orderLink'] as String?,
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      totalStock: (map['totalStock'] ?? 0) as int,
      claimedCount: (map['claimedCount'] ?? 0) as int,
      bookedSlots: (map['bookedSlots'] ?? 0) as int,
      reserveEnabled: (map['reserveEnabled'] ?? false) as bool,
      maxPerCustomer: (map['maxPerCustomer'] ?? 1) as int,
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
      'category': category,
      'imageUrl': imageUrl,
      'originalPrice': originalPrice,
      'offerPrice': offerPrice,
      'currency': currency,
      'type': type,
      'status': status,
      'areaId': areaId,
      'countryCode': countryCode,
      'whatsappNumber': whatsappNumber,
      'orderLink': orderLink,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'totalStock': totalStock,
      'claimedCount': claimedCount,
      'bookedSlots': bookedSlots,
      'reserveEnabled': reserveEnabled,
      'maxPerCustomer': maxPerCustomer,
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
      titleEn: titleEn,
      titleAr: titleAr,
      description: description,
      descriptionEn: descriptionEn,
      descriptionAr: descriptionAr,
      category: category,
      imageUrl: imageUrl ?? this.imageUrl,
      originalPrice: originalPrice,
      offerPrice: offerPrice,
      currency: currency,
      type: type,
      status: status ?? this.status,
      areaId: areaId ?? this.areaId,
      countryCode: countryCode ?? this.countryCode,
      whatsappNumber: whatsappNumber,
      orderLink: orderLink,
      startDate: startDate,
      endDate: endDate,
      totalStock: totalStock,
      claimedCount: claimedCount ?? this.claimedCount,
      bookedSlots: bookedSlots,
      reserveEnabled: reserveEnabled,
      maxPerCustomer: maxPerCustomer,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}