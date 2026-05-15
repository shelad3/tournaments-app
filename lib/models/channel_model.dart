class ChannelModel {
  final String id;
  final String name;
  final String type;
  final String createdBy;
  final DateTime createdAt;

  ChannelModel({
    required this.id,
    required this.name,
    this.type = 'group',
    required this.createdBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'createdBy': createdBy,
    'createdAt': createdAt,
  };

  factory ChannelModel.fromMap(Map<String, dynamic> map, String id) => ChannelModel(
    id: id,
    name: map['name'] ?? '',
    type: map['type'] ?? 'group',
    createdBy: map['createdBy'] ?? '',
    createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );
}
