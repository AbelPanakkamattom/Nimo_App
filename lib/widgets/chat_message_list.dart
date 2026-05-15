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
    // Special UI for voice/video calls
    if (message.isAnyCall) {
      return CallMessageBubble(
        message: message,
        currentUserId: currentUserId,
      );
    }

    final isMe =
        message.senderId == currentUserId;

    final mediaUrl =
        message.mediaUrl ?? '';

    final displayMessage =
    message.type ==
        MessageType.text
        ? message.content
        : (mediaUrl.isNotEmpty
        ? mediaUrl
        : message.content);

    return MessageBubble(
      message: displayMessage,
      time:
      DateTimeFormatter.formatChatTime(
        message.createdAt,
      ),
      isMe: isMe,
      isImage:
      message.type ==
          MessageType.image,
      isAudio:
      message.type ==
          MessageType.audio,
      isDocument:
      message.type ==
          MessageType.document,
      isVideo:
      message.type ==
          MessageType.video,
      status: message.status.name,
      fileName: message.fileName,
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet',
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(14),
      keyboardDismissBehavior:
      ScrollViewKeyboardDismissBehavior
          .onDrag,
      itemCount: messages.length,
      itemBuilder: (
          context,
          index,
          ) {
        return _buildMessage(
          messages[index],
        );
      },
    );
  }
}