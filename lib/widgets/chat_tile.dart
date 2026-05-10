import 'package:flutter/material.dart';

class ChatTile extends StatelessWidget {
  static const Color primary = Color(0xFF6C5CE7);

  final String name;
  final String message;
  final String time;
  final String? avatarUrl;

  final bool isOnline;
  final bool isTyping;
  final bool isMuted;
  final bool isMe;
  final bool isSeen;

  final int unreadCount;

  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onMute;
  final VoidCallback? onArchive;
  final VoidCallback? onViewContact;

  const ChatTile({
    super.key,
    required this.name,
    required this.message,
    required this.time,
    this.avatarUrl,
    this.isOnline = false,
    this.isTyping = false,
    this.isMuted = false,
    this.isMe = false,
    this.isSeen = false,
    this.unreadCount = 0,
    this.onTap,
    this.onDelete,
    this.onMute,
    this.onArchive,
    this.onViewContact,
  });

  // ==========================================
  // MESSAGE STATUS ICON
  // ==========================================

  Widget buildStatusIcon() {
    if (!isMe) {
      return const SizedBox.shrink();
    }

    return Icon(
      Icons.done_all,
      size: 16,
      color: isSeen ? Colors.blue : Colors.grey,
    );
  }

  // ==========================================
  // AVATAR
  // ==========================================

  Widget buildAvatar() {
    final trimmedName = name.trim();
    final initial =
    trimmedName.isNotEmpty
        ? trimmedName[0].toUpperCase()
        : 'N';

    if (avatarUrl != null &&
        avatarUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }

    return CircleAvatar(
      radius: 30,
      backgroundColor: primary,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }

  // ==========================================
  // ONLINE INDICATOR
  // ==========================================

  Widget buildOnlineDot() {
    if (!isOnline) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 2,
      bottom: 2,
      child: Container(
        width: 14,
        height: 14,
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

  // ==========================================
  // UNREAD BADGE
  // ==========================================

  Widget buildUnreadBadge() {
    if (unreadCount <= 0) {
      return const SizedBox.shrink();
    }

    final displayText =
    unreadCount > 99
        ? '99+'
        : unreadCount.toString();

    return Container(
      constraints: const BoxConstraints(
        minWidth: 22,
        minHeight: 22,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: const BoxDecoration(
        color: primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          displayText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MESSAGE PREVIEW
  // ==========================================

  String get previewText {
    if (isTyping) {
      return 'typing...';
    }

    if (isMuted) {
      return 'Muted';
    }

    return message;
  }

  // ==========================================
  // POPUP MENU
  // ==========================================

  void handleMenuSelection(String value) {
    switch (value) {
      case 'view':
        onViewContact?.call();
        break;
      case 'mute':
        onMute?.call();
        break;
      case 'archive':
        onArchive?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 14,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // AVATAR
            Stack(
              children: [
                buildAvatar(),
                buildOnlineDot(),
              ],
            ),

            const SizedBox(width: 14),

            // CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // NAME + TIME
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight
                                .bold,
                            fontSize: 16,
                            color:
                            Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors
                              .grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // MESSAGE PREVIEW
                  Row(
                    children: [
                      buildStatusIcon(),

                      if (isMe)
                        const SizedBox(
                          width: 5,
                        ),

                      Expanded(
                        child: Text(
                          previewText,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style: TextStyle(
                            color: isTyping
                                ? Colors
                                .green
                                : Colors.grey
                                .shade700,
                            fontStyle:
                            isTyping
                                ? FontStyle
                                .italic
                                : FontStyle
                                .normal,
                            fontWeight:
                            unreadCount >
                                0
                                ? FontWeight
                                .w600
                                : FontWeight
                                .normal,
                          ),
                        ),
                      ),

                      if (unreadCount > 0) ...[
                        const SizedBox(
                          width: 8,
                        ),
                        buildUnreadBadge(),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            // MENU
            PopupMenuButton<String>(
              onSelected:
              handleMenuSelection,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  16,
                ),
              ),
              itemBuilder:
                  (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child:
                  Text('View Contact'),
                ),
                PopupMenuItem(
                  value: 'mute',
                  child: Text(
                    isMuted
                        ? 'Unmute'
                        : 'Mute',
                  ),
                ),
                const PopupMenuItem(
                  value: 'archive',
                  child: Text('Archive'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child:
                  Text('Delete Chat'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}