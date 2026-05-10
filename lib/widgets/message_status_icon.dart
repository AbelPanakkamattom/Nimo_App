import 'package:flutter/material.dart';

class MessageStatusIcon extends StatelessWidget {
  /// Possible values:
  /// - sending
  /// - sent
  /// - delivered
  /// - seen / read
  /// - failed
  final String status;

  /// Icon size
  final double size;

  /// Whether the message bubble belongs to the current user.
  /// If true, colors are optimized for purple bubbles.
  /// If false, colors are optimized for white bubbles.
  final bool isMe;

  const MessageStatusIcon({
    super.key,
    required this.status,
    this.size = 16,
    this.isMe = true,
  });

  static const Color primary = Color(0xFF6C5CE7);
  static const Color seenColor = Color(0xFFFFD700); // Golden color

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();

    final Color defaultColor =
    isMe ? Colors.white70 : Colors.grey.shade600;

    switch (normalized) {
    // =====================================================
    // SENDING (spinner)
    // =====================================================
      case 'sending':
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 1.8,
            valueColor: AlwaysStoppedAnimation<Color>(
              defaultColor,
            ),
          ),
        );

    // =====================================================
    // SENT (single tick)
    // =====================================================
      case 'sent':
        return Icon(
          Icons.check,
          size: size,
          color: defaultColor,
        );

    // =====================================================
    // DELIVERED (double tick)
    // =====================================================
      case 'delivered':
        return Icon(
          Icons.done_all,
          size: size,
          color: defaultColor,
        );

    // =====================================================
    // SEEN / READ (golden glowing double tick)
    // =====================================================
      case 'seen':
      case 'read':
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: seenColor.withValues(alpha: 0.7),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.done_all,
            size: size,
            color: seenColor,
          ),
        );

    // =====================================================
    // FAILED
    // =====================================================
      case 'failed':
        return Icon(
          Icons.error_outline,
          size: size,
          color: Colors.redAccent,
        );

    // =====================================================
    // DEFAULT
    // =====================================================
      default:
        return Icon(
          Icons.check,
          size: size,
          color: defaultColor,
        );
    }
  }
}