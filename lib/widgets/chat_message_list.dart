import 'package:flutter/material.dart';

import '../models/message_model.dart';
import '../utils/date_time_formatter.dart';
import 'call_message_bubble.dart';
import 'message_bubble.dart';

class ChatMessageList extends StatelessWidget {
  final List<Message> messages;
  final String currentUserId;
  final ScrollController scrollController;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
  });

  // =========================================================
  // BUILD SINGLE MESSAGE
  // =========================================================

  Widget _buildMessage(Message message) {
    // -------------------------------------------------------
    // Special UI for call and video call messages
    // -------------------------------------------------------
    if (message.isAnyCall) {
      return CallMessageBubble(
        message: message,
        currentUserId: currentUserId,
      );
    }

    // -------------------------------------------------------
    // Current user?
    // -------------------------------------------------------
    final isMe =
        message.senderId == currentUserId;

    // -------------------------------------------------------
    // Use media URL for media messages
    // Use text content for text messages
    // -------------------------------------------------------
    final displayValue = message.isText
        ? message.content
        : message.resolvedUrl;

    // -------------------------------------------------------
    // Build standard message bubble
    // -------------------------------------------------------
    return MessageBubble(
      message: displayValue,
      time: DateTimeFormatter.formatChatTime(
        message.createdAt,
      ),
      isMe: isMe,

      // Media flags
      isImage: message.isImage,
      isAudio: message.isAudio,
      isVideo: message.isVideo,
      isDocument: message.isDocument,

      // Message status
      status: message.status.name,

      // File metadata
      fileName: message.fileName,
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No messages yet',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(14),
      keyboardDismissBehavior:
      ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessage(message);
      },
    );
  }
}