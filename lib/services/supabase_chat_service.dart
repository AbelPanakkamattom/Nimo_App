import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/message_model.dart';

class SupabaseChatService {
  SupabaseChatService._();

  static final SupabaseClient _client = Supabase.instance.client;

  // =========================================================
  // AUTH HELPERS
  // =========================================================

  static User? get currentUser => _client.auth.currentUser;

  static String get myId => currentUser?.id ?? '';

  static bool get isLoggedIn => currentUser != null && myId.isNotEmpty;

  static void _ensureLoggedIn() {
    if (!isLoggedIn) {
      throw Exception('User not logged in.');
    }
  }

  // =========================================================
  // SEND MESSAGE
  // Supports:
  // - text
  // - image
  // - video
  // - file
  // - audio
  // - call
  // - video_call
  //
  // For call/video_call:
  // - call_status defaults to "completed"
  // - call_duration defaults to 0
  // =========================================================

  static Future<void> sendMessage({
    required String receiverId,
    required String content,
    String type = 'text',
    String? replyToMessageId,
    String? mediaUrl,
    String? fileName,
    int? fileSize,
    String? mimeType,

    // Call fields
    String? callStatus,
    int? callDuration,
  }) async {
    _ensureLoggedIn();

    final receiver = receiverId.trim();
    final text = content.trim();

    if (receiver.isEmpty) {
      throw Exception('Receiver ID is empty.');
    }

    // Check if receiver is blocked
    final blocked = await isBlocked(receiver);
    if (blocked) {
      throw Exception('You have blocked this user.');
    }

    final hasText = text.isNotEmpty;
    final hasMedia = mediaUrl != null && mediaUrl.trim().isNotEmpty;
    final isCallMessage = type == 'call' || type == 'video_call';

    // Normal messages require either text or media.
    // Call messages are allowed even if content is empty.
    if (!hasText && !hasMedia && !isCallMessage) {
      throw Exception('Message is empty.');
    }

    // Build payload
    final payload = <String, dynamic>{
      'sender_id': myId,
      'receiver_id': receiver,
      'content': hasText ? text : '',
      'type': type,
      'message_type': type, // supports both schemas
      'status': MessageStatus.sent.name,
      'deleted': false,
      'is_seen': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    // Reply
    if (replyToMessageId != null && replyToMessageId.trim().isNotEmpty) {
      payload['reply_to'] = replyToMessageId.trim();
    }

    // Media
    if (hasMedia) {
      payload['media_url'] = mediaUrl.trim();
      payload['file_url'] = mediaUrl.trim();
    }

    // File information
    if (fileName != null && fileName.trim().isNotEmpty) {
      payload['file_name'] = fileName.trim();
    }

    if (fileSize != null) {
      payload['file_size'] = fileSize;
    }

    if (mimeType != null && mimeType.trim().isNotEmpty) {
      payload['mime_type'] = mimeType.trim();
    }

    // =========================================================
    // CALL SUPPORT
    // =========================================================

    if (isCallMessage) {
      payload['call_status'] =
      (callStatus != null && callStatus.trim().isNotEmpty)
          ? callStatus.trim()
          : 'completed';

      payload['call_duration'] = callDuration ?? 0;
    } else {
      if (callStatus != null && callStatus.trim().isNotEmpty) {
        payload['call_status'] = callStatus.trim();
      }

      if (callDuration != null) {
        payload['call_duration'] = callDuration;
      }
    }

    try {
      await _client.from('messages').insert(payload);
    } on PostgrestException catch (e) {
      debugPrint('SEND MESSAGE ERROR: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('SEND MESSAGE ERROR: $e');
      throw Exception('Failed to send message.');
    }
  }

  // =========================================================
  // CHAT STREAM
  // =========================================================

  static Stream<List<Message>> getChat(String otherUserId) {
    if (!isLoggedIn || otherUserId.trim().isEmpty) {
      return Stream.value(<Message>[]);
    }

    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((rows) {
      try {
        final messages = rows
            .where((row) {
          final sender = row['sender_id']?.toString() ?? '';
          final receiver = row['receiver_id']?.toString() ?? '';

          return (sender == myId && receiver == otherUserId) ||
              (sender == otherUserId && receiver == myId);
        })
            .map(
              (row) => Message.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
            .toList();

        messages.sort(
              (a, b) => a.createdAt.compareTo(b.createdAt),
        );

        _autoMarkDelivered(messages, otherUserId);
        _autoMarkSeen(messages, otherUserId);

        return messages;
      } catch (e) {
        debugPrint('GET CHAT ERROR: $e');
        return <Message>[];
      }
    });
  }

  // =========================================================
  // MARK AS DELIVERED
  // =========================================================

  static Future<void> markAsDelivered(String otherUserId) async {
    if (!isLoggedIn) return;

    try {
      await _client
          .from('messages')
          .update({
        'status': MessageStatus.delivered.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      })
          .eq('sender_id', otherUserId)
          .eq('receiver_id', myId)
          .eq('status', MessageStatus.sent.name);
    } catch (e) {
      debugPrint('MARK DELIVERED ERROR: $e');
    }
  }

  // =========================================================
  // MARK AS SEEN
  // =========================================================

  static Future<void> markAsSeen(String otherUserId) async {
    if (!isLoggedIn) return;

    try {
      await _client
          .from('messages')
          .update({
        'status': MessageStatus.seen.name,
        'is_seen': true,
        'seen_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      })
          .eq('sender_id', otherUserId)
          .eq('receiver_id', myId)
          .neq('status', MessageStatus.seen.name);
    } catch (e) {
      debugPrint('MARK SEEN ERROR: $e');
    }
  }

  static void _autoMarkDelivered(
      List<Message> messages,
      String otherUserId,
      ) {
    final hasPending = messages.any(
          (message) =>
      message.senderId == otherUserId &&
          message.receiverId == myId &&
          message.status == MessageStatus.sent,
    );

    if (hasPending) {
      markAsDelivered(otherUserId);
    }
  }

  static void _autoMarkSeen(
      List<Message> messages,
      String otherUserId,
      ) {
    final hasUnseen = messages.any(
          (message) =>
      message.senderId == otherUserId &&
          message.receiverId == myId &&
          message.status != MessageStatus.seen,
    );

    if (hasUnseen) {
      markAsSeen(otherUserId);
    }
  }

  // =========================================================
  // DELETE MESSAGE
  // =========================================================

  static Future<void> deleteMessage(String messageId) async {
    try {
      await _client.from('messages').delete().eq('id', messageId);
    } catch (_) {
      throw Exception('Failed to delete message.');
    }
  }

  static Future<void> deleteForEveryone(String messageId) async {
    try {
      await _client
          .from('messages')
          .update({
        'content': '🚫 This message was deleted',
        'deleted': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      })
          .eq('id', messageId);
    } catch (e) {
      debugPrint('DELETE FOR EVERYONE ERROR: $e');
    }
  }

  // =========================================================
  // TYPING STATUS
  // =========================================================

  static Future<void> setTyping({
    required String receiverId,
    required bool isTyping,
  }) async {
    if (!isLoggedIn || receiverId.trim().isEmpty) {
      return;
    }

    try {
      await _client.from('typing_status').upsert({
        'user_id': myId,
        'receiver_id': receiverId,
        'is_typing': isTyping,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('SET TYPING ERROR: $e');
    }
  }

  static Stream<bool> typingStream(String otherUserId) {
    if (!isLoggedIn) {
      return Stream.value(false);
    }

    return _client
        .from('typing_status')
        .stream(primaryKey: ['user_id', 'receiver_id'])
        .map((rows) {
      try {
        final row = rows.firstWhere(
              (item) =>
          item['user_id'] == otherUserId &&
              item['receiver_id'] == myId,
        );

        return row['is_typing'] == true;
      } catch (_) {
        return false;
      }
    }).distinct();
  }

  // =========================================================
  // ONLINE STATUS
  // =========================================================

  static Future<void> setOnlineStatus(bool online) async {
    if (!isLoggedIn) return;

    try {
      await _client
          .from('profiles')
          .update({
        'is_online': online,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      })
          .eq('id', myId);
    } catch (e) {
      debugPrint('ONLINE STATUS ERROR: $e');
    }
  }

  static Stream<Map<String, dynamic>> userStatusStream(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) {
      if (rows.isEmpty) {
        return {
          'online': false,
          'last_seen': null,
        };
      }

      final profile = rows.first;

      return {
        'online': profile['is_online'] == true,
        'last_seen': profile['last_seen'],
      };
    });
  }

  // =========================================================
  // UNREAD COUNT
  // =========================================================

  static Stream<int> unreadCountStream(String otherUserId) {
    if (!isLoggedIn) {
      return Stream.value(0);
    }

    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((rows) {
      return rows.where((row) {
        return row['sender_id'] == otherUserId &&
            row['receiver_id'] == myId &&
            row['status'] != MessageStatus.seen.name;
      }).length;
    });
  }

  // =========================================================
  // BLOCK USER
  // =========================================================

  static Future<void> blockUser({
    required String blockedId,
  }) async {
    if (!isLoggedIn || blockedId.trim().isEmpty) {
      return;
    }

    try {
      await _client.from('blocked_users').upsert({
        'blocker_id': myId,
        'blocked_id': blockedId,
      });
    } catch (e) {
      debugPrint('BLOCK USER ERROR: $e');
    }
  }

  // =========================================================
  // UNBLOCK USER
  // =========================================================

  static Future<void> unblockUser(String blockedId) async {
    if (!isLoggedIn || blockedId.trim().isEmpty) {
      return;
    }

    try {
      await _client.from('blocked_users').delete().match({
        'blocker_id': myId,
        'blocked_id': blockedId,
      });
    } catch (e) {
      debugPrint('UNBLOCK USER ERROR: $e');
    }
  }

  // =========================================================
  // CHECK IF BLOCKED
  // =========================================================

  static Future<bool> isBlocked(String otherUserId) async {
    if (!isLoggedIn || otherUserId.trim().isEmpty) {
      return false;
    }

    try {
      final result = await _client
          .from('blocked_users')
          .select()
          .eq('blocker_id', myId)
          .eq('blocked_id', otherUserId)
          .maybeSingle();

      return result != null;
    } catch (_) {
      return false;
    }
  }
}