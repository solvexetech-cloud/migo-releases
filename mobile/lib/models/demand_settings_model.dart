// mobile/lib/models/demand_settings_model.dart
// NEW FILE - Super Admin demand settings
// Created: Nov 09, 2026
// Purpose: Threshold, expiry, grouping settings controlled by Super Admin

import 'package:cloud_firestore/cloud_firestore.dart';

class DemandSettingsModel {
  final int defaultThreshold;
  final Map<String, int> categoryThresholds;
  final int autoGroupWindowHours;
  final int demandExpiryDays;
  final bool allowPrivateBulk;
  final int privateBulkMinQuantity;
  final DateTime updatedAt;
  final String updatedBy;

  DemandSettingsModel({
    required this.defaultThreshold,
    required this.categoryThresholds,
    required this.autoGroupWindowHours,
    required this.demandExpiryDays,
    required this.allowPrivateBulk,
    required this.privateBulkMinQuantity,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory DemandSettingsModel.defaults() {
    return DemandSettingsModel(
      defaultThreshold: 3,
      categoryThresholds: {},
      autoGroupWindowHours: 72,
      demandExpiryDays: 7,
      allowPrivateBulk: true,
      privateBulkMinQuantity: 10,
      updatedAt: DateTime.now(),
      updatedBy: 'system',
    );
  }

  factory DemandSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return DemandSettingsModel.defaults();

    return DemandSettingsModel(
      defaultThreshold: data['defaultThreshold'] ?? 3,
      categoryThresholds: Map<String, int>.from(
        (data['categoryThresholds'] as Map?) ?? {},
      ),
      autoGroupWindowHours: data['autoGroupWindowHours'] ?? 72,
      demandExpiryDays: data['demandExpiryDays'] ?? 7,
      allowPrivateBulk: data['allowPrivateBulk'] ?? true,
      privateBulkMinQuantity: data['privateBulkMinQuantity'] ?? 10,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: data['updatedBy'] ?? 'system',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'defaultThreshold': defaultThreshold,
      'categoryThresholds': categoryThresholds,
      'autoGroupWindowHours': autoGroupWindowHours,
      'demandExpiryDays': demandExpiryDays,
      'allowPrivateBulk': allowPrivateBulk,
      'privateBulkMinQuantity': privateBulkMinQuantity,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }

  int thresholdForCategory(String category) {
    return categoryThresholds[category] ?? defaultThreshold;
  }

  bool isPrivateBulk(int quantity) {
    return allowPrivateBulk && quantity >= privateBulkMinQuantity;
  }

  DemandSettingsModel copyWith({
    int? defaultThreshold,
    Map<String, int>? categoryThresholds,
    int? autoGroupWindowHours,
    int? demandExpiryDays,
    bool? allowPrivateBulk,
    int? privateBulkMinQuantity,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return DemandSettingsModel(
      defaultThreshold: defaultThreshold ?? this.defaultThreshold,
      categoryThresholds: categoryThresholds ?? this.categoryThresholds,
      autoGroupWindowHours: autoGroupWindowHours ?? this.autoGroupWindowHours,
      demandExpiryDays: demandExpiryDays ?? this.demandExpiryDays,
      allowPrivateBulk: allowPrivateBulk ?? this.allowPrivateBulk,
      privateBulkMinQuantity: privateBulkMinQuantity ?? this.privateBulkMinQuantity,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}