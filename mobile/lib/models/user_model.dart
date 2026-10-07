import 'package:cloud_firestore/cloud_firestore.dart';

/// MIGO user profile data (stored in Firestore at users/{uid}).
class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phone,
    this.country = 'QA',
    this.currentAreaId,
    this.currentCountryCode,
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
  /// User's currently selected area (persisted).
  final String? currentAreaId;

  /// User's currently selected country code.
  final String? currentCountryCode;
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
      currentAreaId: map['currentAreaId'] as String?,
      currentCountryCode: map['currentCountryCode'] as String?,
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
      'currentAreaId': currentAreaId,
      'currentCountryCode': currentCountryCode,
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
    String? currentAreaId,
    String? currentCountryCode,
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
      currentAreaId: currentAreaId ?? this.currentAreaId,
      currentCountryCode:
      currentCountryCode ?? this.currentCountryCode,
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



/// MIGO user roles — 6-tier system.
///
/// Tier order (highest to lowest):
///   super_admin > admin > moderator > agency > business > customer
extension UserRoleX on UserModel {
  /// Raw role string (safe default: customer)
  String get roleId => role.isEmpty ? 'customer' : role;

  /// Display name for UI
  String get roleLabel {
    switch (roleId) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'moderator':
        return 'Moderator';
      case 'agency':
        return 'Agency';
      case 'business':
        return 'Business Owner';
      case 'customer':
      default:
        return 'Customer';
    }
  }

  /// Is this user the platform owner?
  bool get isSuperAdmin => roleId == 'super_admin';

  /// Is this user an admin or above?
  bool get isAdmin => roleId == 'admin' || roleId == 'super_admin';

  /// Is this user a moderator or above?
  bool get isModerator =>
      roleId == 'moderator' || roleId == 'admin' || roleId == 'super_admin';

  /// Is this user an agency partner?
  bool get isAgency => roleId == 'agency';

  /// Is this user a business owner?
  bool get isBusiness => roleId == 'business';

  /// Is this user a regular customer?
  bool get isCustomer => roleId == 'customer';

  /// Can this user access the admin panel?
  bool get canAccessAdminPanel => isModerator;

  /// Can this user manage categories?
  bool get canManageCategories => isModerator;

  /// Can this user approve/reject businesses?
  bool get canApproveBusinesses => isModerator;

  /// Can this user approve/reject offers?
  bool get canApproveOffers => isModerator;

  /// Can this user manage other users' roles?
  bool get canManageRoles => isAdmin;

  /// Can this user delete businesses?
  bool get canDeleteBusinesses => isAdmin;

  /// Can this user delete users?
  bool get canDeleteUsers => isSuperAdmin;

  /// Color theme for role badges (hex strings)
  String get roleColor {
    switch (roleId) {
      case 'super_admin':
        return '#7C3AED'; // Purple
      case 'admin':
        return '#D64545'; // Red
      case 'moderator':
        return '#A67920'; // Amber
      case 'agency':
        return '#0E7490'; // Teal
      case 'business':
        return '#1E4B8F'; // Blue
      case 'customer':
      default:
        return '#2E9E5B'; // Green
    }
  }
}