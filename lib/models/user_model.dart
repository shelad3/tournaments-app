enum UserRole { user, admin, superAdmin }

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String username;
  final String phoneNumber;
  final String? photoUrl;
  final String? favoriteTeam;
  final List<String> favoriteGames;
  final UserRole role;
  final List<String> permissions;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.username,
    required this.phoneNumber,
    this.photoUrl,
    this.favoriteTeam,
    this.favoriteGames = const [],
    this.role = UserRole.user,
    this.permissions = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;
  bool get isSuperAdmin => role == UserRole.superAdmin;

  bool hasPermission(String permission) =>
      isSuperAdmin || permissions.contains(permission);

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'fullName': fullName,
    'email': email,
    'username': username,
    'phoneNumber': phoneNumber,
    'photoUrl': photoUrl,
    'favoriteTeam': favoriteTeam,
    'favoriteGames': favoriteGames,
    'role': role.name,
    'permissions': permissions,
    'createdAt': createdAt,
  };

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) => UserModel(
    uid: uid,
    fullName: map['fullName'] ?? '',
    email: map['email'] ?? '',
    username: map['username'] ?? '',
    phoneNumber: map['phoneNumber'] ?? '',
    photoUrl: map['photoUrl'],
    favoriteTeam: map['favoriteTeam'],
    favoriteGames: List<String>.from(map['favoriteGames'] ?? []),
    role: _parseRole(map['role']),
    permissions: List<String>.from(map['permissions'] ?? []),
    createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'superAdmin':
        return UserRole.superAdmin;
      default:
        return UserRole.user;
    }
  }
}
