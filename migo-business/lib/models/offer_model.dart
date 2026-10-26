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
    String? id,
    String? businessId,
    String? businessName,
    String? title,
    String? titleEn,
    String? titleAr,
    String? description,
    String? descriptionEn,
    String? descriptionAr,
    String? category,
    String? imageUrl,
    double? originalPrice,
    double? offerPrice,
    String? currency,
    String? type,
    String? status,
    String? areaId,
    DateTime? startDate,
    DateTime? endDate,
    int? totalStock,
    int? claimedCount,
    int? bookedSlots,
    bool? reserveEnabled,
    int? maxPerCustomer,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OfferModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      title: title ?? this.title,
      titleEn: titleEn ?? this.titleEn,
      titleAr: titleAr ?? this.titleAr,
      description: description ?? this.description,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      originalPrice: originalPrice ?? this.originalPrice,
      offerPrice: offerPrice ?? this.offerPrice,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      status: status ?? this.status,
      areaId: areaId ?? this.areaId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalStock: totalStock ?? this.totalStock,
      claimedCount: claimedCount ?? this.claimedCount,
      bookedSlots: bookedSlots ?? this.bookedSlots,
      reserveEnabled: reserveEnabled ?? this.reserveEnabled,
      maxPerCustomer: maxPerCustomer ?? this.maxPerCustomer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}