import 'package:flutter/material.dart';

import '../models/message_model.dart';
import '../utils/date_time_formatter.dart';

class CallMessageBubble extends StatelessWidget {
  final Message message;
  final String currentUserId;
  final Color primaryColor;

  const CallMessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    this.primaryColor = const Color(0xFF6C5CE7),
  });

  // =========================================================
  // HELPERS
  // =========================================================

  bool get _isMe {
    return message.senderId == currentUserId;
  }

  bool get _isMissed {
    return message.isMissedCall;
  }

  bool get _isVideo {
    return message.isVideoCall;
  }

  IconData get _callIcon {
    return _isVideo ? Icons.videocam : Icons.call;
  }

  Color get _bubbleColor {
    return _isMe ? primaryColor : Colors.white;
  }

  Color get _textColor {
    return _isMe ? Colors.white : Colors.black87;
  }

  Color get _secondaryColor {
    return _isMe ? Colors.white70 : Colors.grey.shade600;
  }

  Color get _iconColor {
    if (_isMissed) {
      return Colors.redAccent;
    }

    return _isMe ? Colors.white : primaryColor;
  }

  String get _description {
    return message.callDescription(currentUserId);
  }

  // =========================================================
  // FORMAT DURATION
  // =========================================================

  String get _durationText {
    final seconds = message.callDuration ?? 0;
    return DateTimeFormatter.formatDuration(seconds);
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
      _isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth:
          MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: _bubbleColor,
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
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // =================================================
            // CALL ICON + DESCRIPTION
            // =================================================
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _callIcon,
                  color: _iconColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _description,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 15,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // =================================================
            // CALL DURATION
            // =================================================
            if (_durationText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _durationText,
                style: TextStyle(
                  color: _secondaryColor,
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 8),

            // =================================================
            // TIME + READ RECEIPTS
            // =================================================
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateTimeFormatter.formatChatTime(
                    message.createdAt,
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color: _secondaryColor,
                  ),
                ),
                if (_isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 16,
                    color: message.isSeen
                        ? const Color(
                      0xFFFFD700,
                    )
                        : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}