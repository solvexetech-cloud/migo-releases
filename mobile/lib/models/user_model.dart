import 'package:cloud_firestore/cloud_firestore.dart';

/// MIGO user profile data (stored in Firestore at users/{uid}).
class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phone,
    this.country = 'QA',
    this.city = 'Doha',
    this.currency = 'QAR',
    this.locale = 'en',
    this.coins = 0,
    this.loyaltyLevel = 'Bronze',
    this.role = 'customer',
    this.referralCode,
    this.referredBy,
    this.hasCompletedFirstClaim = false,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? phone;
  final String country;
  final String city;
  final String currency;
  final String locale;
  final int coins;
  final String loyaltyLevel;

  /// customer | business | creator | admin
  final String role;

  /// Short unique code this user shares (e.g. "4K9PZ2").
  final String? referralCode;

  /// If this user signed up with a referral, the referrer's uid.
  final String? referredBy;

  /// True once the user completes their first claim.
  final bool hasCompletedFirstClaim;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserModel.fresh({
    required String uid,
    required String email,
    String? displayName,
    String? referralCode,
    String? referredBy,
  }) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      referralCode: referralCode,
      referredBy: referredBy,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      email: (map['email'] ?? '') as String,
      displayName: map['displayName'] as String?,
      phone: map['phone'] as String?,
      country: (map['country'] ?? 'QA') as String,
      city: (map['city'] ?? 'Doha') as String,
      currency: (map['currency'] ?? 'QAR') as String,
      locale: (map['locale'] ?? 'en') as String,
      coins: (map['coins'] ?? 0) as int,
      loyaltyLevel: (map['loyaltyLevel'] ?? 'Bronze') as String,
      role: (map['role'] ?? 'customer') as String,
      referralCode: map['referralCode'] as String?,
      referredBy: map['referredBy'] as String?,
      hasCompletedFirstClaim:
          (map['hasCompletedFirstClaim'] ?? false) as bool,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'country': country,
      'city': city,
      'currency': currency,
      'locale': locale,
      'coins': coins,
      'loyaltyLevel': loyaltyLevel,
      'role': role,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'hasCompletedFirstClaim': hasCompletedFirstClaim,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? phone,
    String? country,
    String? city,
    String? currency,
    String? locale,
    int? coins,
    String? loyaltyLevel,
    String? role,
    String? referralCode,
    String? referredBy,
    bool? hasCompletedFirstClaim,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      city: city ?? this.city,
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      coins: coins ?? this.coins,
      loyaltyLevel: loyaltyLevel ?? this.loyaltyLevel,
      role: role ?? this.role,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      hasCompletedFirstClaim:
          hasCompletedFirstClaim ?? this.hasCompletedFirstClaim,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}