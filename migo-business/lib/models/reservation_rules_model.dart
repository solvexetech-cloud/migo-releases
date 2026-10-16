// ═══════════════════════════════════════════════════════
// MIGO — Reservation Rules Model (PHASE H)
// ═══════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationRulesModel {
  final String id;
  final String version;
  final String title;
  final String textEn;
  final String textAr;
  final String textMl;
  final DateTime? effectiveFrom;
  final bool active;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;

  ReservationRulesModel({
    required this.id,
    required this.version,
    required this.title,
    required this.textEn,
    required this.textAr,
    required this.textMl,
    this.effectiveFrom,
    required this.active,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
  });

  String textForLocale(String locale) {
    switch (locale) {
      case 'ar':
        return textAr;
      case 'ml':
        return textMl;
      case 'en':
      default:
        return textEn;
    }
  }

  factory ReservationRulesModel.fromMap(
      String id, Map<String, dynamic> data) {
    return ReservationRulesModel(
      id: id,
      version: data['version'] ?? 'v1.0',
      title: data['title'] ?? 'MIGO Reserve Rules',
      textEn: data['textEn'] ?? '',
      textAr: data['textAr'] ?? '',
      textMl: data['textMl'] ?? '',
      effectiveFrom: (data['effectiveFrom'] as Timestamp?)?.toDate(),
      active: data['active'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'title': title,
      'textEn': textEn,
      'textAr': textAr,
      'textMl': textMl,
      'effectiveFrom':
          effectiveFrom != null ? Timestamp.fromDate(effectiveFrom!) : null,
      'active': active,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'createdBy': createdBy,
      'updatedAt':
          updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  ReservationRulesModel copyWith({
    String? title,
    String? textEn,
    String? textAr,
    String? textMl,
    bool? active,
    DateTime? updatedAt,
  }) {
    return ReservationRulesModel(
      id: id,
      version: version,
      title: title ?? this.title,
      textEn: textEn ?? this.textEn,
      textAr: textAr ?? this.textAr,
      textMl: textMl ?? this.textMl,
      effectiveFrom: effectiveFrom,
      active: active ?? this.active,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ReservationRulesModel.empty() {
    return ReservationRulesModel(
      id: '',
      version: '',
      title: '',
      textEn: '',
      textAr: '',
      textMl: '',
      active: false,
    );
  }
}