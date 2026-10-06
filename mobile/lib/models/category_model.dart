import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Category data (Firestore: categories/{id}).
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.order = 0,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String icon;
  final int order;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) {
    return CategoryModel(
      id: id,
      name: (map['name'] ?? '') as String,
      icon: (map['icon'] ?? 'category_outlined') as String,
      order: (map['order'] ?? 0) as int,
      active: (map['active'] ?? true) as bool,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'order': order,
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Map icon string to Flutter IconData.
  /// Tree-shaking safe: only listed icons bundled.
  IconData get iconData {
    switch (icon) {
      // Original 9
      case 'restaurant_outlined':
        return Icons.restaurant_outlined;
      case 'spa_outlined':
        return Icons.spa_outlined;
      case 'directions_car_outlined':
        return Icons.directions_car_outlined;
      case 'celebration_outlined':
        return Icons.celebration_outlined;
      case 'camera_alt_outlined':
        return Icons.camera_alt_outlined;
      case 'fitness_center_outlined':
        return Icons.fitness_center_outlined;
      case 'shopping_bag_outlined':
        return Icons.shopping_bag_outlined;
      case 'school_outlined':
        return Icons.school_outlined;
      case 'home_repair_service_outlined':
        return Icons.home_repair_service_outlined;

      // Additional icons for admin
      case 'local_cafe_outlined':
        return Icons.local_cafe_outlined;
      case 'local_pizza_outlined':
        return Icons.local_pizza_outlined;
      case 'bakery_dining_outlined':
        return Icons.bakery_dining_outlined;
      case 'icecream_outlined':
        return Icons.icecream_outlined;
      case 'local_florist_outlined':
        return Icons.local_florist_outlined;
      case 'content_cut_outlined':
        return Icons.content_cut_outlined;
      case 'face_retouching_natural_outlined':
        return Icons.face_retouching_natural_outlined;
      case 'spa':
        return Icons.spa;
      case 'pets_outlined':
        return Icons.pets_outlined;
      case 'child_care_outlined':
        return Icons.child_care_outlined;
      case 'sports_soccer_outlined':
        return Icons.sports_soccer_outlined;
      case 'sports_basketball_outlined':
        return Icons.sports_basketball_outlined;
      case 'self_improvement_outlined':
        return Icons.self_improvement_outlined;
      case 'book_outlined':
        return Icons.book_outlined;
      case 'computer_outlined':
        return Icons.computer_outlined;
      case 'phone_iphone_outlined':
        return Icons.phone_iphone_outlined;
      case 'checkroom_outlined':
        return Icons.checkroom_outlined;
      case 'watch_outlined':
        return Icons.watch_outlined;
      case 'diamond_outlined':
        return Icons.diamond_outlined;
      case 'local_hospital_outlined':
        return Icons.local_hospital_outlined;
      case 'medication_outlined':
        return Icons.medication_outlined;
      case 'local_laundry_service_outlined':
        return Icons.local_laundry_service_outlined;
      case 'cleaning_services_outlined':
        return Icons.cleaning_services_outlined;
      case 'plumbing_outlined':
        return Icons.plumbing_outlined;
      case 'electrical_services_outlined':
        return Icons.electrical_services_outlined;
      case 'local_shipping_outlined':
        return Icons.local_shipping_outlined;
      case 'flight_outlined':
        return Icons.flight_outlined;
      case 'hotel_outlined':
        return Icons.hotel_outlined;
      case 'event_outlined':
        return Icons.event_outlined;
      case 'music_note_outlined':
        return Icons.music_note_outlined;
      case 'movie_outlined':
        return Icons.movie_outlined;
      case 'sports_esports_outlined':
        return Icons.sports_esports_outlined;
      case 'toys_outlined':
        return Icons.toys_outlined;

      default:
        return Icons.category_outlined;
    }
  }
}