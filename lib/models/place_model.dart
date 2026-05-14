class PlaceModel {
  final String id;
  final String name;
  final String location;
  final String? imageUrl;
  final List<String> adminIds;
  final DateTime createdAt;

  PlaceModel({
    required this.id,
    required this.name,
    required this.location,
    this.imageUrl,
    this.adminIds = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'name': name,
    'location': location,
    'imageUrl': imageUrl,
    'adminIds': adminIds,
    'createdAt': createdAt,
  };

  factory PlaceModel.fromMap(Map<String, dynamic> map, String id) => PlaceModel(
    id: id,
    name: map['name'] ?? '',
    location: map['location'] ?? '',
    imageUrl: map['imageUrl'],
    adminIds: List<String>.from(map['adminIds'] ?? []),
    createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );
}
