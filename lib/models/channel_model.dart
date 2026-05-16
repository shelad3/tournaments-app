enum ChannelType { global, public, adminOnly }

class ChannelModel {
  final String id;
  final String name;
  final ChannelType type;
  final String createdBy;
  final DateTime createdAt;

  ChannelModel({
    required this.id,
    required this.name,
    this.type = ChannelType.public,
    required this.createdBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get typeLabel {
    switch (type) {
      case ChannelType.global: return 'Default';
      case ChannelType.public: return 'Public';
      case ChannelType.adminOnly: return 'Admin Only';
    }
  }

  bool get isAdminOnly => type == ChannelType.adminOnly;

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type.name,
    'createdBy': createdBy,
    'createdAt': createdAt,
  };

  factory ChannelModel.fromMap(Map<String, dynamic> map, String id) => ChannelModel(
    id: id,
    name: map['name'] ?? '',
    type: _parseType(map['type']),
    createdBy: map['createdBy'] ?? '',
    createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  static ChannelType _parseType(String? type) {
    switch (type) {
      case 'adminOnly': return ChannelType.adminOnly;
      case 'public': return ChannelType.public;
      default: return ChannelType.global;
    }
  }
}
