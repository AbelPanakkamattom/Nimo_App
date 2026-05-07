import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/message_model.dart';

class SupabaseChatService {
  static final SupabaseClient _client =
      Supabase.instance.client;

  /// =====================================
  /// 👤 CURRENT USER
  /// =====================================

  static User? get currentUser =>
      _client.auth.currentUser;

  static String get myId =>
      currentUser?.id ?? '';

  /// =====================================
  /// 📤 SEND MESSAGE
  /// =====================================

  static Future<void> sendMessage({
    required String receiverId,
    required String content,
    String type = 'text',
    String? replyToMessageId,
  }) async {
    if (currentUser == null) {
      throw Exception(
        'User not logged in',
      );
    }

    final text = content.trim();

    if (text.isEmpty) return;

    try {
      await _client
          .from('messages')
          .insert({
        'sender_id': myId,
        'receiver_id': receiverId,
        'content': text,
        'type': type,
        'status':
        MessageStatus.sent.name,
        'reply_to':
        replyToMessageId,
        'deleted': false,
        'created_at':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
      });
    } catch (e) {
      throw Exception(
        'Send failed: $e',
      );
    }
  }

  /// =====================================
  /// 💬 CHAT STREAM
  /// =====================================

  static Stream<List<Message>> getChat(
      String otherUserId,
      ) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((rows) {
      try {
        final filtered =
        rows.where((msg) {
          return (msg['sender_id'] ==
              myId &&
              msg['receiver_id'] ==
                  otherUserId) ||
              (msg['sender_id'] ==
                  otherUserId &&
                  msg['receiver_id'] ==
                      myId);
        }).toList();

        /// REMOVE DUPLICATES
        final Map<String, dynamic>
        unique = {};

        for (final item
        in filtered) {
          unique[item['id']
              .toString()] =
              item;
        }

        final parsed = unique.values
            .map(
              (e) => Message.fromJson(
            Map<String, dynamic>.from(
              e,
            ),
          ),
        )
            .toList();

        /// SORT ASC
        parsed.sort(
              (a, b) => a.createdAt
              .compareTo(
            b.createdAt,
          ),
        );

        /// AUTO STATUS
        _autoDelivered(
          parsed,
          otherUserId,
        );

        _autoSeen(
          parsed,
          otherUserId,
        );

        return parsed;
      } catch (_) {
        return [];
      }
    });
  }

  /// =====================================
  /// 👀 MARK SEEN
  /// =====================================

  static Future<void> markAsSeen(
      String otherUserId,
      ) async {
    try {
      await _client
          .from('messages')
          .update({
        'status':
        MessageStatus.seen.name,
      })
          .eq(
        'sender_id',
        otherUserId,
      )
          .eq(
        'receiver_id',
        myId,
      )
          .neq(
        'status',
        MessageStatus.seen.name,
      );
    } catch (_) {}
  }

  /// =====================================
  /// 🚚 MARK DELIVERED
  /// =====================================

  static Future<void>
  markAsDelivered(
      String otherUserId,
      ) async {
    try {
      await _client
          .from('messages')
          .update({
        'status':
        MessageStatus
            .delivered
            .name,
      })
          .eq(
        'sender_id',
        otherUserId,
      )
          .eq(
        'receiver_id',
        myId,
      )
          .eq(
        'status',
        MessageStatus.sent.name,
      );
    } catch (_) {}
  }

  /// =====================================
  /// ⚡ AUTO DELIVERED
  /// =====================================

  static void _autoDelivered(
      List<Message> messages,
      String otherUserId,
      ) {
    final hasPending =
    messages.any(
          (m) =>
      m.senderId ==
          otherUserId &&
          m.receiverId == myId &&
          m.status ==
              MessageStatus.sent,
    );

    if (hasPending) {
      markAsDelivered(
        otherUserId,
      );
    }
  }

  /// =====================================
  /// 👀 AUTO SEEN
  /// =====================================

  static void _autoSeen(
      List<Message> messages,
      String otherUserId,
      ) {
    final hasUnseen =
    messages.any(
          (m) =>
      m.senderId ==
          otherUserId &&
          m.receiverId == myId &&
          m.status !=
              MessageStatus.seen,
    );

    if (hasUnseen) {
      markAsSeen(
        otherUserId,
      );
    }
  }

  /// =====================================
  /// 🗑 DELETE MESSAGE
  /// =====================================

  static Future<void>
  deleteMessage(
      String messageId,
      ) async {
    try {
      await _client
          .from('messages')
          .delete()
          .eq(
        'id',
        messageId,
      );
    } catch (e) {
      throw Exception(
        'Delete failed: $e',
      );
    }
  }

  /// =====================================
  /// 🚫 DELETE FOR EVERYONE
  /// =====================================

  static Future<void>
  deleteForEveryone(
      String messageId,
      ) async {
    try {
      await _client
          .from('messages')
          .update({
        'content':
        '🚫 This message was deleted',
        'deleted': true,
      })
          .eq(
        'id',
        messageId,
      );
    } catch (_) {}
  }

  /// =====================================
  /// ✍️ SET TYPING
  /// =====================================

  static Future<void> setTyping({
    required String receiverId,
    required bool isTyping,
  }) async {
    try {
      await _client
          .from('typing_status')
          .upsert({
        'user_id': myId,
        'receiver_id':
        receiverId,
        'is_typing':
        isTyping,
        'updated_at':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
      });
    } catch (_) {}
  }

  /// =====================================
  /// ✍️ TYPING STREAM
  /// =====================================

  static Stream<bool> typingStream(
      String otherUserId,
      ) {
    return _client
        .from('typing_status')
        .stream(
      primaryKey: ['user_id'],
    )
        .map((rows) {
      try {
        final data =
        rows.firstWhere(
              (e) =>
          e['user_id'] ==
              otherUserId &&
              e['receiver_id'] ==
                  myId,
        );

        return data['is_typing'] ==
            true;
      } catch (_) {
        return false;
      }
    });
  }

  /// =====================================
  /// 🟢 ONLINE STATUS
  /// =====================================

  static Future<void>
  setOnlineStatus(
      bool online,
      ) async {
    try {
      await _client
          .from('profiles')
          .update({
        'is_online': online,
        'last_seen':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
      })
          .eq('id', myId);
    } catch (_) {}
  }

  /// =====================================
  /// 🟢 USER STATUS STREAM
  /// =====================================

  static Stream<
      Map<String, dynamic>>
  userStatusStream(
      String userId,
      ) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((rows) {
      try {
        final user =
        rows.firstWhere(
              (e) => e['id'] == userId,
        );

        return {
          'online':
          user['is_online'] ??
              false,
          'last_seen':
          user['last_seen'],
        };
      } catch (_) {
        return {
          'online': false,
          'last_seen': null,
        };
      }
    });
  }

  /// =====================================
  /// 🔴 UNREAD COUNT
  /// =====================================

  static Stream<int>
  unreadCountStream(
      String otherUserId,
      ) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((rows) {
      return rows.where((m) {
        return m['sender_id'] ==
            otherUserId &&
            m['receiver_id'] ==
                myId &&
            m['status'] != 'seen';
      }).length;
    });
  }

  /// =====================================
  /// 📌 PIN CHAT
  /// =====================================

  static Future<void> pinChat({
    required String otherUserId,
  }) async {
    try {
      await _client
          .from('pinned_chats')
          .upsert({
        'user_id': myId,
        'chat_user_id':
        otherUserId,
      });
    } catch (_) {}
  }

  /// =====================================
  /// 📦 ARCHIVE CHAT
  /// =====================================

  static Future<void>
  archiveChat({
    required String otherUserId,
  }) async {
    try {
      await _client
          .from('archived_chats')
          .upsert({
        'user_id': myId,
        'chat_user_id':
        otherUserId,
      });
    } catch (_) {}
  }

  /// =====================================
  /// 🚫 BLOCK USER
  /// =====================================

  static Future<void> blockUser({
    required String blockedId,
  }) async {
    try {
      await _client
          .from('blocked_users')
          .upsert({
        'blocker_id': myId,
        'blocked_id': blockedId,
      });
    } catch (_) {}
  }

  /// =====================================
  /// ✅ CHECK BLOCK
  /// =====================================

  static Future<bool> isBlocked(
      String otherUserId,
      ) async {
    try {
      final data = await _client
          .from('blocked_users')
          .select()
          .eq(
        'blocker_id',
        myId,
      )
          .eq(
        'blocked_id',
        otherUserId,
      )
          .maybeSingle();

      return data != null;
    } catch (_) {
      return false;
    }
  }
}