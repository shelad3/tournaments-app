class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final String? relatedId;
  final String? imageUrl;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.read = false,
    DateTime? createdAt,
    this.relatedId,
    this.imageUrl,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'type': type,
    'title': title,
    'body': body,
    'read': read,
    'createdAt': createdAt,
    'relatedId': relatedId,
    'imageUrl': imageUrl,
  };

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) =>
      AppNotification(
        id: id,
        userId: map['userId'] ?? '',
        type: map['type'] ?? '',
        title: map['title'] ?? '',
        body: map['body'] ?? '',
        read: map['read'] ?? false,
        createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
        relatedId: map['relatedId'],
        imageUrl: map['imageUrl'],
      );

  AppNotification copyWith({bool? read}) =>
      AppNotification(
        id: id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        read: read ?? this.read,
        createdAt: createdAt,
        relatedId: relatedId,
        imageUrl: imageUrl,
      );
}
