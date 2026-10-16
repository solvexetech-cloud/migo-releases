// ═══════════════════════════════════════════════════════
// MIGO — Reservation Model (PHASE H)
// ═══════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String id;

  // Core references
  final String userUid;
  final String userName;
  final String userPhone;

  final String businessId;
  final String businessName;
  final String businessPhone;

  final String offerId;
  final String offerTitle;
  final String offerImageUrl;

  // Quantity & Pricing
  final int quantity;
  final double unitPrice;
  final double originalPrice;
  final String currency;
  final double totalAmount;

  // Timing
  final DateTime bookedAt;
  final DateTime expiresAt;
  final DateTime? pickedUpAt;
  final DateTime? cancelledAt;
  final String? cancelledBy;

  // Status
  final String status;

  // Pickup
  final String pickupCode;
  final String qrCode;

  // Token
  final bool tokenRequired;
  final double tokenAmount;
  final String? tokenPaymentId;
  final bool tokenRefunded;
  final bool tokenForfeited;

  // Location
  final String areaId;
  final String countryCode;
  final String zoneId;

  // Metadata
  final String? notes;
  final String source;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReservationModel({
    required this.id,
    required this.userUid,
    required this.userName,
    required this.userPhone,
    required this.businessId,
    required this.businessName,
    required this.businessPhone,
    required this.offerId,
    required this.offerTitle,
    required this.offerImageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.originalPrice,
    required this.currency,
    required this.totalAmount,
    required this.bookedAt,
    required this.expiresAt,
    this.pickedUpAt,
    this.cancelledAt,
    this.cancelledBy,
    required this.status,
    required this.pickupCode,
    required this.qrCode,
    this.tokenRequired = false,
    this.tokenAmount = 0,
    this.tokenPaymentId,
    this.tokenRefunded = false,
    this.tokenForfeited = false,
    required this.areaId,
    required this.countryCode,
    required this.zoneId,
    this.notes,
    this.source = 'app',
    this.createdAt,
    this.updatedAt,
  });

  // Computed
  bool get isActive => status == 'reserved';
  bool get isPickedUp => status == 'picked_up';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => isPickedUp || isExpired || isCancelled;

  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  double get remainingPercent {
    final total = expiresAt.difference(bookedAt).inSeconds;
    final left = timeRemaining.inSeconds;
    if (total <= 0) return 0;
    return (left / total).clamp(0.0, 1.0);
  }

  factory ReservationModel.fromMap(String id, Map<String, dynamic> data) {
    return ReservationModel(
      id: id,
      userUid: data['userUid'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'] ?? '',
      businessId: data['businessId'] ?? '',
      businessName: data['businessName'] ?? '',
      businessPhone: data['businessPhone'] ?? '',
      offerId: data['offerId'] ?? '',
      offerTitle: data['offerTitle'] ?? '',
      offerImageUrl: data['offerImageUrl'] ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0,
      originalPrice: (data['originalPrice'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] ?? 'QAR',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      bookedAt: (data['bookedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt:
          (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pickedUpAt: (data['pickedUpAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      cancelledBy: data['cancelledBy'],
      status: data['status'] ?? 'reserved',
      pickupCode: data['pickupCode'] ?? '',
      qrCode: data['qrCode'] ?? '',
      tokenRequired: data['tokenRequired'] ?? false,
      tokenAmount: (data['tokenAmount'] as num?)?.toDouble() ?? 0,
      tokenPaymentId: data['tokenPaymentId'],
      tokenRefunded: data['tokenRefunded'] ?? false,
      tokenForfeited: data['tokenForfeited'] ?? false,
      areaId: data['areaId'] ?? '',
      countryCode: data['countryCode'] ?? 'QA',
      zoneId: data['zoneId'] ?? '',
      notes: data['notes'],
      source: data['source'] ?? 'app',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userUid': userUid,
      'userName': userName,
      'userPhone': userPhone,
      'businessId': businessId,
      'businessName': businessName,
      'businessPhone': businessPhone,
      'offerId': offerId,
      'offerTitle': offerTitle,
      'offerImageUrl': offerImageUrl,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'originalPrice': originalPrice,
      'currency': currency,
      'totalAmount': totalAmount,
      'bookedAt': Timestamp.fromDate(bookedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'pickedUpAt':
          pickedUpAt != null ? Timestamp.fromDate(pickedUpAt!) : null,
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancelledBy': cancelledBy,
      'status': status,
      'pickupCode': pickupCode,
      'qrCode': qrCode,
      'tokenRequired': tokenRequired,
      'tokenAmount': tokenAmount,
      'tokenPaymentId': tokenPaymentId,
      'tokenRefunded': tokenRefunded,
      'tokenForfeited': tokenForfeited,
      'areaId': areaId,
      'countryCode': countryCode,
      'zoneId': zoneId,
      'notes': notes,
      'source': source,
    };
  }

  ReservationModel copyWith({
    String? status,
    DateTime? pickedUpAt,
    DateTime? cancelledAt,
    String? cancelledBy,
    DateTime? updatedAt,
  }) {
    return ReservationModel(
      id: id,
      userUid: userUid,
      userName: userName,
      userPhone: userPhone,
      businessId: businessId,
      businessName: businessName,
      businessPhone: businessPhone,
      offerId: offerId,
      offerTitle: offerTitle,
      offerImageUrl: offerImageUrl,
      quantity: quantity,
      unitPrice: unitPrice,
      originalPrice: originalPrice,
      currency: currency,
      totalAmount: totalAmount,
      bookedAt: bookedAt,
      expiresAt: expiresAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      status: status ?? this.status,
      pickupCode: pickupCode,
      qrCode: qrCode,
      tokenRequired: tokenRequired,
      tokenAmount: tokenAmount,
      tokenPaymentId: tokenPaymentId,
      tokenRefunded: tokenRefunded,
      tokenForfeited: tokenForfeited,
      areaId: areaId,
      countryCode: countryCode,
      zoneId: zoneId,
      notes: notes,
      source: source,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}