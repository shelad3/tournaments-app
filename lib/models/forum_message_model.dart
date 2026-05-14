enum ForumMessageType { text, image, voice }

class ForumMessageModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String? text;
  final String? imageUrl;
  final String? voiceUrl;
  final ForumMessageType type;
  final DateTime createdAt;

  ForumMessageModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.text,
    this.imageUrl,
    this.voiceUrl,
    this.type = ForumMessageType.text,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'userPhotoUrl': userPhotoUrl,
    'text': text,
    'imageUrl': imageUrl,
    'voiceUrl': voiceUrl,
    'type': type.name,
    'createdAt': createdAt,
  };

  factory ForumMessageModel.fromMap(Map<String, dynamic> map, String id) => ForumMessageModel(
    id: id,
    userId: map['userId'] ?? '',
    userName: map['userName'] ?? '',
    userPhotoUrl: map['userPhotoUrl'],
    text: map['text'],
    imageUrl: map['imageUrl'],
    voiceUrl: map['voiceUrl'],
    type: _parseType(map['type']),
    createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  static ForumMessageType _parseType(String? t) {
    switch (t) {
      case 'image':
        return ForumMessageType.image;
      case 'voice':
        return ForumMessageType.voice;
      default:
        return ForumMessageType.text;
    }
  }
}
