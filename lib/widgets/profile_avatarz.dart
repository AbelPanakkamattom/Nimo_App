import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;

  final double radius;

  final bool isOnline;
  final bool showOnlineStatus;

  final VoidCallback? onTap;

  final bool showBorder;
  final Color borderColor;
  final double borderWidth;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 28,
    this.isOnline = false,
    this.showOnlineStatus = true,
    this.onTap,
    this.showBorder = false,
    this.borderColor = Colors.white,
    this.borderWidth = 2,
  });

  static const Color primary =
  Color(0xFF6C5CE7);

  // ==========================================
  // INITIAL
  // ==========================================

  String get initial {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return '?';
    }

    return trimmed[0].toUpperCase();
  }

  bool get hasImage {
    return imageUrl != null &&
        imageUrl!.trim().isNotEmpty;
  }

  // ==========================================
  // DEFAULT AVATAR
  // ==========================================

  Widget buildDefaultAvatar() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            primary,
            Color(0xFF8E7CFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight:
          FontWeight.bold,
          fontSize: radius * 0.78,
        ),
      ),
    );
  }

  // ==========================================
  // NETWORK AVATAR
  // ==========================================

  Widget buildNetworkAvatar() {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder:
            (context, url) =>
            Container(
              width: radius * 2,
              height: radius * 2,
              color:
              Colors.grey.shade200,
              alignment:
              Alignment.center,
              child: SizedBox(
                width: radius * 0.6,
                height: radius * 0.6,
                child:
                const CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
        errorWidget:
            (
            context,
            url,
            error,
            ) =>
            buildDefaultAvatar(),
      ),
    );
  }

  // ==========================================
  // AVATAR
  // ==========================================

  Widget buildAvatar() {
    final avatar =
    hasImage
        ? buildNetworkAvatar()
        : buildDefaultAvatar();

    if (!showBorder) {
      return avatar;
    }

    return Container(
      padding:
      EdgeInsets.all(
        borderWidth,
      ),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: borderColor,
      ),
      child: avatar,
    );
  }

  // ==========================================
  // ONLINE DOT
  // ==========================================

  Widget buildOnlineDot() {
    if (!showOnlineStatus ||
        !isOnline) {
      return const SizedBox.shrink();
    }

    final dotSize =
        radius * 0.52;

    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green
                  .withAlpha(90),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        buildAvatar(),
        buildOnlineDot(),
      ],
    );

    if (onTap == null) {
      return avatar;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder:
        const CircleBorder(),
        child: avatar,
      ),
    );
  }
}