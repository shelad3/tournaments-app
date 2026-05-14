import 'package:flutter/material.dart';
import '../screens/profile/profile_screen.dart';

class AvatarHelper {
  static int? parseIndex(String? photoUrl) {
    if (photoUrl == null || !photoUrl.startsWith('avatar:')) return null;
    return int.tryParse(photoUrl.substring(7));
  }

  static bool isBuiltIn(String? photoUrl) => photoUrl?.startsWith('avatar:') ?? false;
  static bool isCustomUpload(String? photoUrl) =>
      photoUrl != null && !photoUrl.startsWith('avatar:');

  static Widget buildCircleAvatar(String? photoUrl, double radius, {BuildContext? context}) {
    final index = parseIndex(photoUrl);
    if (index != null && index >= 0 && index < builtInAvatars.length) {
      final avatar = builtInAvatars[index];
      return CircleAvatar(
        radius: radius,
        backgroundColor: avatar.color.withValues(alpha: 0.2),
        child: Icon(avatar.icon, size: radius, color: avatar.color),
      );
    }
    if (isCustomUpload(photoUrl)) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      child: Icon(Icons.person, size: radius, color: Colors.grey),
    );
  }
}
