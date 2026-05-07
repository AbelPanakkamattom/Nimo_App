import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final String time;

  final bool isMe;
  final bool isSeen;

  final bool isImage;
  final bool isAudio;

  const MessageBubble({
    super.key,
    required this.message,
    required this.time,
    this.isMe = false,
    this.isSeen = false,
    this.isImage = false,
    this.isAudio = false,
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
      color: Colors.white70,
    );
  }

  /// =========================
  /// MESSAGE CONTENT
  /// =========================

  Widget buildContent() {
    if (isImage) {
      return ClipRRect(
        borderRadius:
        BorderRadius.circular(16),
        child: Image.network(
          message,
          width: 220,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) {
            return Container(
              width: 220,
              height: 180,
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(
                  Icons.broken_image,
                ),
              ),
            );
          },
        ),
      );
    }

    if (isAudio) {
      return Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            Icons.mic,
            color: isMe
                ? Colors.white
                : Colors.black,
          ),

          const SizedBox(width: 8),

          Text(
            "Voice Message",
            style: TextStyle(
              color: isMe
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ],
      );
    }

    return Text(
      message,
      style: TextStyle(
        color:
        isMe
            ? Colors.white
            : Colors.black,
        fontSize: 15,
      ),
    );
  }

  /// =========================
  /// UI
  /// =========================

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
      isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
        const BoxConstraints(
          maxWidth: 300,
        ),
        margin:
        const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 5,
        ),
        padding:
        const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
          isMe
              ? const Color(
            0xFF6C5CE7,
          )
              : Colors.white,
          borderRadius:
          BorderRadius.circular(
            20,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withAlpha(8),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.end,
          children: [
            buildContent(),

            const SizedBox(height: 6),

            Row(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color:
                    isMe
                        ? Colors.white70
                        : Colors.grey,
                    fontSize: 10,
                  ),
                ),

                if (isMe) ...[
                  const SizedBox(width: 5),
                  buildStatusIcon(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}