import 'package:flutter/material.dart';

class ChatTile extends StatelessWidget {
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

  /// =========================
  /// STATUS ICON
  /// =========================

  Widget buildStatusIcon() {
    if (!isMe) {
      return const SizedBox();
    }

    if (isSeen) {
      return const Icon(
        Icons.done_all,
        size: 16,
        color: Colors.amber,
      );
    }

    return const Icon(
      Icons.done_all,
      size: 16,
      color: Colors.grey,
    );
  }

  /// =========================
  /// AVATAR
  /// =========================

  Widget buildAvatar() {
    if (avatarUrl != null &&
        avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundImage:
        NetworkImage(
          avatarUrl!,
        ),
      );
    }

    return CircleAvatar(
      radius: 30,
      backgroundColor:
      const Color(0xFF6C5CE7),
      child: Text(
        name.isNotEmpty
            ? name[0].toUpperCase()
            : "?",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }

  /// =========================
  /// ONLINE DOT
  /// =========================

  Widget buildOnlineDot() {
    if (!isOnline) {
      return const SizedBox();
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

  /// =========================
  /// UNREAD BADGE
  /// =========================

  Widget buildUnreadBadge() {
    if (unreadCount <= 0) {
      return const SizedBox();
    }

    return Container(
      padding:
      const EdgeInsets.all(7),
      decoration:
      const BoxDecoration(
        color: Color(0xFF6C5CE7),
        shape: BoxShape.circle,
      ),
      child: Text(
        unreadCount.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight:
          FontWeight.bold,
        ),
      ),
    );
  }

  /// =========================
  /// UI
  /// =========================

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius:
      BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        margin:
        const EdgeInsets.only(
          bottom: 14,
        ),
        padding:
        const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
            24,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withAlpha(8),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            /// AVATAR
            Stack(
              children: [
                buildAvatar(),
                buildOnlineDot(),
              ],
            ),

            const SizedBox(width: 14),

            /// CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
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
                          ),
                        ),
                      ),

                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      buildStatusIcon(),

                      if (isMe)
                        const SizedBox(
                          width: 5,
                        ),

                      Expanded(
                        child: Text(
                          isTyping
                              ? "typing..."
                              : isMuted
                              ? "Muted"
                              : message,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style: TextStyle(
                            color: isTyping
                                ? Colors
                                .green
                                : Colors
                                .grey
                                .shade700,
                            fontStyle:
                            isTyping
                                ? FontStyle
                                .italic
                                : FontStyle
                                .normal,
                          ),
                        ),
                      ),

                      buildUnreadBadge(),
                    ],
                  ),
                ],
              ),
            ),

            /// MENU
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value ==
                    'view' &&
                    onViewContact !=
                        null) {
                  onViewContact!();
                }

                if (value ==
                    'mute' &&
                    onMute != null) {
                  onMute!();
                }

                if (value ==
                    'archive' &&
                    onArchive !=
                        null) {
                  onArchive!();
                }

                if (value ==
                    'delete' &&
                    onDelete !=
                        null) {
                  onDelete!();
                }
              },
              itemBuilder: (_) => [
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
                  child:
                  Text('Archive'),
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