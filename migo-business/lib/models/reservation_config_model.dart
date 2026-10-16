// ═══════════════════════════════════════════════════════
// MIGO — Reservation Config Model (PHASE H)
// ═══════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationConfigModel {
  final String id;
  final bool enabled;

  final int defaultHoldHours;
  final int maxHoldHours;
  final int minHoldHours;

  final bool tokenRequired;
  final double tokenAmount;
  final double tokenMinAmount;
  final double tokenMaxAmount;

  final int noShowLimit7Day;
  final int noShowLimit30Day;
  final int banDurationDays;

  final bool locationLockEnabled;
  final double locationLockRadiusKm;

  final List<int> reminderHoursBefore;
  final int reminderMinutesBefore;

  final DateTime? updatedAt;
  final String? updatedBy;

  ReservationConfigModel({
    required this.id,
    required this.enabled,
    required this.defaultHoldHours,
    required this.maxHoldHours,
    required this.minHoldHours,
    required this.tokenRequired,
    required this.tokenAmount,
    required this.tokenMinAmount,
    required this.tokenMaxAmount,
    required this.noShowLimit7Day,
    required this.noShowLimit30Day,
    required this.banDurationDays,
    required this.locationLockEnabled,
    required this.locationLockRadiusKm,
    required this.reminderHoursBefore,
    required this.reminderMinutesBefore,
    this.updatedAt,
    this.updatedBy,
  });

  factory ReservationConfigModel.defaults() {
    return ReservationConfigModel(
      id: 'global',
      enabled: true,
      defaultHoldHours: 4,
      maxHoldHours: 24,
      minHoldHours: 1,
      tokenRequired: false,
      tokenAmount: 0,
      tokenMinAmount: 5,
      tokenMaxAmount: 50,
      noShowLimit7Day: 3,
      noShowLimit30Day: 5,
      banDurationDays: 7,
      locationLockEnabled: true,
      locationLockRadiusKm: 5,
      reminderHoursBefore: [1, 2],
      reminderMinutesBefore: 30,
    );
  }

  factory ReservationConfigModel.fromMap(
      String id, Map<String, dynamic> data) {
    return ReservationConfigModel(
      id: id,
      enabled: data['enabled'] ?? true,
      defaultHoldHours: (data['defaultHoldHours'] as num?)?.toInt() ?? 4,
      maxHoldHours: (data['maxHoldHours'] as num?)?.toInt() ?? 24,
      minHoldHours: (data['minHoldHours'] as num?)?.toInt() ?? 1,
      tokenRequired: data['tokenRequired'] ?? false,
      tokenAmount: (data['tokenAmount'] as num?)?.toDouble() ?? 0,
      tokenMinAmount: (data['tokenMinAmount'] as num?)?.toDouble() ?? 5,
      tokenMaxAmount: (data['tokenMaxAmount'] as num?)?.toDouble() ?? 50,
      noShowLimit7Day: (data['noShowLimit7Day'] as num?)?.toInt() ?? 3,
      noShowLimit30Day: (data['noShowLimit30Day'] as num?)?.toInt() ?? 5,
      banDurationDays: (data['banDurationDays'] as num?)?.toInt() ?? 7,
      locationLockEnabled: data['locationLockEnabled'] ?? true,
      locationLockRadiusKm:
          (data['locationLockRadiusKm'] as num?)?.toDouble() ?? 5,
      reminderHoursBefore: (data['reminderHoursBefore'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [1, 2],
      reminderMinutesBefore:
          (data['reminderMinutesBefore'] as num?)?.toInt() ?? 30,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'defaultHoldHours': defaultHoldHours,
      'maxHoldHours': maxHoldHours,
      'minHoldHours': minHoldHours,
      'tokenRequired': tokenRequired,
      'tokenAmount': tokenAmount,
      'tokenMinAmount': tokenMinAmount,
      'tokenMaxAmount': tokenMaxAmount,
      'noShowLimit7Day': noShowLimit7Day,
      'noShowLimit30Day': noShowLimit30Day,
      'banDurationDays': banDurationDays,
      'locationLockEnabled': locationLockEnabled,
      'locationLockRadiusKm': locationLockRadiusKm,
      'reminderHoursBefore': reminderHoursBefore,
      'reminderMinutesBefore': reminderMinutesBefore,
    };
  }

  ReservationConfigModel copyWith({
    bool? enabled,
    int? defaultHoldHours,
    int? maxHoldHours,
    int? minHoldHours,
    bool? tokenRequired,
    double? tokenAmount,
    double? tokenMinAmount,
    double? tokenMaxAmount,
    int? noShowLimit7Day,
    int? noShowLimit30Day,
    int? banDurationDays,
    bool? locationLockEnabled,
    double? locationLockRadiusKm,
    List<int>? reminderHoursBefore,
    int? reminderMinutesBefore,
  }) {
    return ReservationConfigModel(
      id: id,
      enabled: enabled ?? this.enabled,
      defaultHoldHours: defaultHoldHours ?? this.defaultHoldHours,
      maxHoldHours: maxHoldHours ?? this.maxHoldHours,
      minHoldHours: minHoldHours ?? this.minHoldHours,
      tokenRequired: tokenRequired ?? this.tokenRequired,
      tokenAmount: tokenAmount ?? this.tokenAmount,
      tokenMinAmount: tokenMinAmount ?? this.tokenMinAmount,
      tokenMaxAmount: tokenMaxAmount ?? this.tokenMaxAmount,
      noShowLimit7Day: noShowLimit7Day ?? this.noShowLimit7Day,
      noShowLimit30Day: noShowLimit30Day ?? this.noShowLimit30Day,
      banDurationDays: banDurationDays ?? this.banDurationDays,
      locationLockEnabled: locationLockEnabled ?? this.locationLockEnabled,
      locationLockRadiusKm:
          locationLockRadiusKm ?? this.locationLockRadiusKm,
      reminderHoursBefore: reminderHoursBefore ?? this.reminderHoursBefore,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }
}