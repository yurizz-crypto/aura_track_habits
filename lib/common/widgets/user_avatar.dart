import 'package:flutter/material.dart';

/// Displays a circular user image or a fallback initial if no image is provided.
/// Optionally displays an "edit" pencil icon overlay.
class UserAvatar extends StatelessWidget {
  /// Remote URL for the profile image. If null, displays initials.
  final String? avatarUrl;

  /// Used to generate initials if [avatarUrl] is null.
  final String username;

  /// The size of the avatar circle.
  final double radius;

  /// Callback when the avatar is tapped (e.g., to upload a new photo).
  final VoidCallback? onTap;

  /// If `true`, shows a small pencil icon at the bottom-right.
  final bool showEditIcon;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.username = "User",
    this.radius = 20,
    this.onTap,
    this.showEditIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.teal.shade100,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Text(
        (username.isNotEmpty ? username[0] : "A").toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.teal,
          fontSize: radius * 0.8,
        ),
      )
          : null,
    );

    if (!showEditIcon) return avatar;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          avatar,
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
            child: const Icon(Icons.edit, color: Colors.white, size: 20),
          )
        ],
      ),
    );
  }
}