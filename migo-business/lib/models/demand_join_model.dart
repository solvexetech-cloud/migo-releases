import 'package:cloud_firestore/cloud_firestore.dart';

class DemandJoinModel {
  final String id;
  final String demandId;
  final String userId;
  final String userName;
  final DateTime joinedAt;

  DemandJoinModel({
    required this.id,
    required this.demandId,
    required this.userId,
    required this.userName,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'demandId': demandId,
      'userId': userId,
      'userName': userName,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory DemandJoinModel.fromMap(String id, Map<String, dynamic> map) {
    return DemandJoinModel(
      id: id,
      demandId: map['demandId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'User',
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
