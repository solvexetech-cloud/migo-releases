import 'package:cloud_firestore/cloud_firestore.dart';

class CreatorModel {
  final String id;
  final String userId;
  final String displayName;
  final String bio;
  final String photoUrl;
  final String city;
  final List<String> categories;
  final String phoneOrWhatsapp;
  final String? instagramUrl;
  final String? tiktokUrl;
  final String? youtubeUrl;
  final int followersCount;
  final String status; // pending, approved, rejected, suspended
  final String? rejectionReason;
  final DateTime? approvedAt;
  final DateTime createdAt;

  CreatorModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.bio,
    required this.photoUrl,
    required this.city,
    required this.categories,
    required this.phoneOrWhatsapp,
    this.instagramUrl,
    this.tiktokUrl,
    this.youtubeUrl,
    required this.followersCount,
    required this.status,
    this.rejectionReason,
    this.approvedAt,
    required this.createdAt,
  });

  factory CreatorModel.fromMap(String id, Map<String, dynamic> map) {
    return CreatorModel(
      id: id,
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      bio: map['bio'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      city: map['city'] ?? '',
      categories: List<String>.from(map['categories'] ?? []),
      phoneOrWhatsapp: map['phoneOrWhatsapp'] ?? '',
      instagramUrl: map['instagramUrl'],
      tiktokUrl: map['tiktokUrl'],
      youtubeUrl: map['youtubeUrl'],
      followersCount: (map['followersCount'] as num? ?? 0).toInt(),
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejectionReason'],
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'bio': bio,
      'photoUrl': photoUrl,
      'city': city,
      'categories': categories,
      'phoneOrWhatsapp': phoneOrWhatsapp,
      'instagramUrl': instagramUrl,
      'tiktokUrl': tiktokUrl,
      'youtubeUrl': youtubeUrl,
      'followersCount': followersCount,
      'status': status,
      'rejectionReason': rejectionReason,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}