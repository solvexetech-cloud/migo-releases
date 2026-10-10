import 'package:cloud_firestore/cloud_firestore.dart';

/// Language data (Firestore: languages/{code}).
class LanguageModel {
  const LanguageModel({
    required this.code,
    required this.name,
    required this.nameNative,
    this.rtl = false,
    this.order = 0,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final String code; // 'en', 'ar'
  final String name; // 'English', 'Arabic'
  final String nameNative; // 'English', 'العربية'
  final bool rtl;
  final int order;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory LanguageModel.fromMap(String code, Map<String, dynamic> map) {
    return LanguageModel(
      code: code,
      name: (map['name'] ?? '') as String,
      nameNative: (map['nameNative'] ?? '') as String,
      rtl: (map['rtl'] ?? false) as bool,
      order: (map['order'] ?? 0) as int,
      active: (map['active'] ?? true) as bool,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'nameNative': nameNative,
        'rtl': rtl,
        'order': order,
        'active': active,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}