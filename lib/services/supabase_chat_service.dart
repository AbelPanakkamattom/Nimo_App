import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

class SupabaseChatService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// ============================
  /// 📩 SEND MESSAGE
  /// ============================
  static Future<void> sendMessage({
    required String receiverId,
    required String content,
    String type = 'text',
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    final text = content.trim();
    if (text.isEmpty) return;

    try {
      await _client.from('messages').insert({
        'sender_id': user.id,
        'receiver_id': receiverId,
        'content': text,
        'type': type,
        'status': MessageStatus.sent.name,
      });
    } catch (e) {
      throw Exception("Send failed: $e");
    }
  }

  /// ============================
  /// 🔴 CHAT STREAM (FIXED)
  /// ============================
  static Stream<List<Message>> getChat(String otherUserId) async* {
    final user = _client.auth.currentUser;

    if (user == null) {
      yield [];
      return;
    }

    try {
      /// 🔥 1. LOAD OLD MESSAGES FIRST
      final initial = await _client
          .from('messages')
          .select()
          .or(
        'and(sender_id.eq.${user.id},receiver_id.eq.$otherUserId),'
            'and(sender_id.eq.$otherUserId,receiver_id.eq.${user.id})',
      )
          .order('created_at', ascending: true);

      List<Message> messages = Message.fromList(initial);

      /// 👀 AUTO STATUS UPDATE
      _autoMarkDelivered(messages, user.id, otherUserId);
      _autoMarkSeen(messages, user.id, otherUserId);

      yield messages;

      /// 🔥 2. REALTIME STREAM
      final stream = _client
          .from('messages')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: true);

      await for (final data in stream) {
        try {
          final allMessages = Message.fromList(data);

          final filtered = allMessages.where((msg) {
            return (msg.senderId == user.id &&
                msg.receiverId == otherUserId) ||
                (msg.senderId == otherUserId &&
                    msg.receiverId == user.id);
          }).toList();

          final unique = {
            for (var m in filtered) m.id: m,
          }.values.toList();

          messages = unique;

          /// 👀 AUTO STATUS UPDATE
          _autoMarkDelivered(messages, user.id, otherUserId);
          _autoMarkSeen(messages, user.id, otherUserId);

          yield messages;
        } catch (_) {
          yield messages;
        }
      }
    } catch (e) {
      yield [];
    }
  }

  /// ============================
  /// 👀 MARK AS SEEN
  /// ============================
  static Future<void> markAsSeen(String otherUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client
          .from('messages')
          .update({'status': MessageStatus.seen.name})
          .eq('sender_id', otherUserId)
          .eq('receiver_id', user.id)
          .neq('status', MessageStatus.seen.name);
    } catch (_) {}
  }

  /// ============================
  /// 🚚 MARK AS DELIVERED
  /// ============================
  static Future<void> markAsDelivered(String otherUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client
          .from('messages')
          .update({'status': MessageStatus.delivered.name})
          .eq('sender_id', otherUserId)
          .eq('receiver_id', user.id)
          .eq('status', MessageStatus.sent.name);
    } catch (_) {}
  }

  /// ============================
  /// 🔥 AUTO SEEN
  /// ============================
  static void _autoMarkSeen(
      List<Message> messages,
      String myId,
      String otherUserId,
      ) {
    final unseen = messages.where((m) =>
    m.senderId == otherUserId &&
        m.receiverId == myId &&
        m.status != MessageStatus.seen);

    if (unseen.isNotEmpty) {
      markAsSeen(otherUserId);
    }
  }

  /// ============================
  /// 🚚 AUTO DELIVERED
  /// ============================
  static void _autoMarkDelivered(
      List<Message> messages,
      String myId,
      String otherUserId,
      ) {
    final undelivered = messages.where((m) =>
    m.senderId == otherUserId &&
        m.receiverId == myId &&
        m.status == MessageStatus.sent);

    if (undelivered.isNotEmpty) {
      markAsDelivered(otherUserId);
    }
  }

  /// ============================
  /// 🗑 DELETE MESSAGE
  /// ============================
  static Future<void> deleteMessage(String messageId) async {
    try {
      await _client.from('messages').delete().eq('id', messageId);
    } catch (e) {
      throw Exception("Delete failed: $e");
    }
  }

  /// ============================
  /// ✍️ TYPING INDICATOR (FUTURE)
  /// ============================
  static Future<void> setTyping({
    required String receiverId,
    required bool isTyping,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('typing').upsert({
        'user_id': user.id,
        'receiver_id': receiverId,
        'is_typing': isTyping,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }
}