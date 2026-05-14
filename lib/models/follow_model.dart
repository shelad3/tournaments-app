class FollowModel {
  final String id;
  final String followerId;
  final String followingId;
  final DateTime createdAt;

  FollowModel({
    required this.id,
    required this.followerId,
    required this.followingId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'followerId': followerId,
    'followingId': followingId,
    'createdAt': createdAt,
  };

  factory FollowModel.fromMap(Map<String, dynamic> map, String id) => FollowModel(
    id: id,
    followerId: map['followerId'] ?? '',
    followingId: map['followingId'] ?? '',
    createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );
}
