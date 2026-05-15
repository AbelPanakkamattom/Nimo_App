import 'package:flutter/material.dart';

import '../utils/date_time_formatter.dart';
import 'profile_avatarz.dart';

class ChatAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String otherUserName;
  final String? otherUserAvatar;
  final bool isOnline;
  final DateTime? lastSeen;
  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;

  const ChatAppBar({
    super.key,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.onVoiceCall,
    required this.onVideoCall,
    this.isOnline = true,
    this.lastSeen,
  });

  static const Color primary =
  Color(0xFF6C5CE7);

  // =========================================================
  // STATUS TEXT
  // =========================================================

  String get _statusText {
    if (isOnline) {
      return 'Online';
    }

    return DateTimeFormatter.formatLastSeen(
      lastSeen,
    );
  }

  // =========================================================
  // STATUS COLOR
  // =========================================================

  Color get _statusColor {
    if (isOnline) {
      return Colors.green;
    }

    return Colors.grey;
  }

  // =========================================================
  // APP BAR SIZE
  // =========================================================

  @override
  Size get preferredSize =>
      const Size.fromHeight(
        kToolbarHeight,
      );

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      titleSpacing: 0,
      centerTitle: false,
      title: Row(
        children: [
          ProfileAvatar(
            name: otherUserName,
            imageUrl: otherUserAvatar,
            radius: 20,
            isOnline: isOnline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Text(
                  otherUserName,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _statusText,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Voice Call',
          onPressed: onVoiceCall,
          icon: const Icon(
            Icons.call,
          ),
        ),
        IconButton(
          tooltip: 'Video Call',
          onPressed: onVideoCall,
          icon: const Icon(
            Icons.videocam,
          ),
        ),
      ],
    );
  }
}