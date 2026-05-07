import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;

  final double radius;

  final bool isOnline;
  final bool showOnlineStatus;

  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 28,
    this.isOnline = false,
    this.showOnlineStatus = true,
    this.onTap,
  });

  /// =========================
  /// INITIAL
  /// =========================

  String get initial {
    if (name.trim().isEmpty) {
      return "?";
    }

    return name
        .trim()
        .substring(0, 1)
        .toUpperCase();
  }

  /// =========================
  /// AVATAR
  /// =========================

  Widget buildAvatar() {
    if (imageUrl != null &&
        imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage:
        NetworkImage(imageUrl!),
        backgroundColor:
        Colors.grey.shade200,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor:
      const Color(0xFF6C5CE7),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight:
          FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }

  /// =========================
  /// ONLINE DOT
  /// =========================

  Widget buildOnlineDot() {
    if (!showOnlineStatus ||
        !isOnline) {
      return const SizedBox();
    }

    return Positioned(
      right: 2,
      bottom: 2,
      child: Container(
        width: radius * 0.38,
        height: radius * 0.38,
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
      ),
    );
  }

  /// =========================
  /// UI
  /// =========================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          buildAvatar(),
          buildOnlineDot(),
        ],
      ),
    );
  }
}