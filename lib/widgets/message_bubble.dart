import 'package:flutter/material.dart';

import 'message_status_icon.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isMe;

  // Media flags
  final bool isImage;
  final bool isAudio;
  final bool isDocument;
  final bool isVideo;

  // Call flags
  final bool isCall;
  final bool isVideoCall;
  final bool isMissedCall;

  // Delivery status
  final String status;

  // Optional file name for documents
  final String? fileName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.time,
    required this.isMe,
    this.isImage = false,
    this.isAudio = false,
    this.isDocument = false,
    this.isVideo = false,
    this.isCall = false,
    this.isVideoCall = false,
    this.isMissedCall = false,
    this.status = 'sent',
    this.fileName,
  });

  static const Color primary = Color(0xFF6C5CE7);

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? primary : Colors.white;
    final textColor = isMe ? Colors.white : Colors.black87;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildContent(textColor),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe ? Colors.white70 : Colors.grey,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  MessageStatusIcon(
                    status: status,
                    size: 16,
                    isMe: true,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Color textColor) {
    // =====================================================
    // CALL MESSAGE (VOICE CALL)
    // =====================================================
    if (isCall) {
      return _buildCallTile(
        icon: Icons.call,
        textColor: textColor,
        isVideo: false,
      );
    }

    // =====================================================
    // CALL MESSAGE (VIDEO CALL)
    // =====================================================
    if (isVideoCall) {
      return _buildCallTile(
        icon: Icons.videocam,
        textColor: textColor,
        isVideo: true,
      );
    }

    // =====================================================
    // IMAGE
    // =====================================================
    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          message,
          width: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Text(
              '📷 Image',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
            );
          },
        ),
      );
    }

    // =====================================================
    // DOCUMENT
    // =====================================================
    if (isDocument) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file,
            color: isMe ? Colors.white : Colors.grey.shade700,
            size: 28,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              fileName ?? message,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }

    // =====================================================
    // AUDIO
    // =====================================================
    if (isAudio) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_arrow,
            color: isMe ? Colors.white : Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            'Voice Message',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    // =====================================================
    // VIDEO FILE
    // =====================================================
    if (isVideo) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.videocam,
            color: isMe ? Colors.white : Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            'Video',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    // =====================================================
    // TEXT MESSAGE
    // =====================================================
    return Text(
      message,
      style: TextStyle(
        color: textColor,
        fontSize: 16,
      ),
    );
  }

  Widget _buildCallTile({
    required IconData icon,
    required Color textColor,
    required bool isVideo,
  }) {
    final bool incoming = !isMe;

    String title;
    if (message.trim().isNotEmpty) {
      title = message;
    } else {
      if (isMissedCall) {
        title = incoming
            ? (isVideo ? 'Missed video call' : 'Missed voice call')
            : (isVideo ? 'Video call not answered' : 'Voice call not answered');
      } else {
        title = incoming
            ? (isVideo ? 'Incoming video call' : 'Incoming voice call')
            : (isVideo ? 'You started a video call' : 'You started a voice call');
      }
    }

    Color iconColor;
    if (isMissedCall) {
      iconColor = isMe ? Colors.orangeAccent : Colors.redAccent;
    } else {
      iconColor = isMe ? Colors.white : primary;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}