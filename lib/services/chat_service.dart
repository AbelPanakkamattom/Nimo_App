import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  static final SupabaseClient supabase =
      Supabase.instance.client;

  /// =========================
  /// SEND TEXT MESSAGE
  /// =========================

  static Future<bool> sendMessage({
    required String receiverId,
    required String content,
    String type = 'text',
  }) async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint("USER NULL");
        return false;
      }

      await supabase.from('messages').insert({
        'sender_id': user.id,
        'receiver_id': receiverId,
        'content': content,
        'type': type,
        'status': 'sent',
        'created_at':
        DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint(
        "SEND MESSAGE ERROR: $e",
      );

      return false;
    }
  }

  /// =========================
  /// SEND IMAGE MESSAGE
  /// =========================

  static Future<bool> sendImageMessage({
    required String receiverId,
    required File imageFile,
  }) async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        return false;
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.jpg';

      final filePath =
          'chat_images/${user.id}/$fileName';

      /// upload image
      await supabase.storage
          .from('message')
          .upload(
        filePath,
        imageFile,
        fileOptions:
        const FileOptions(
          upsert: true,
        ),
      );

      /// get public url
      final imageUrl = supabase.storage
          .from('message')
          .getPublicUrl(filePath);

      /// insert message
      await supabase.from('messages').insert({
        'sender_id': user.id,
        'receiver_id': receiverId,
        'content': imageUrl,
        'type': 'image',
        'status': 'sent',
        'created_at':
        DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint(
        "SEND IMAGE ERROR: $e",
      );

      return false;
    }
  }

  /// =========================
  /// GET CHAT MESSAGES
  /// =========================

  static Stream<List<Map<String, dynamic>>>
  getMessages(String otherUserId) {
    final myId =
        supabase.auth.currentUser!.id;

    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order(
      'created_at',
      ascending: true,
    )
        .map((messages) {
      return messages.where((msg) {
        final sender =
        msg['sender_id'];
        final receiver =
        msg['receiver_id'];

        return (sender == myId &&
            receiver ==
                otherUserId) ||
            (sender ==
                otherUserId &&
                receiver == myId);
      }).toList();
    });
  }

  /// =========================
  /// GET CHATS
  /// =========================

  static Stream<List<Map<String, dynamic>>>
  getChats() {
    final myId =
        supabase.auth.currentUser!.id;

    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order(
      'created_at',
      ascending: false,
    )
        .map((messages) {
      final Map<String,
          Map<String, dynamic>>
      latestChats = {};

      for (final msg in messages) {
        final sender =
        msg['sender_id'];
        final receiver =
        msg['receiver_id'];

        if (sender != myId &&
            receiver != myId) {
          continue;
        }

        final otherUserId =
        sender == myId
            ? receiver
            : sender;

        if (!latestChats.containsKey(
            otherUserId)) {
          latestChats[
          otherUserId] =
              msg;
        }
      }

      return latestChats.values
          .toList();
    });
  }

  /// =========================
  /// MARK AS SEEN
  /// =========================

  static Future<void> markAsSeen(
      String senderId) async {
    try {
      final myId =
          supabase.auth.currentUser!.id;

      await supabase
          .from('messages')
          .update({
        'status': 'seen',
      })
          .eq(
        'sender_id',
        senderId,
      )
          .eq(
        'receiver_id',
        myId,
      );
    } catch (e) {
      debugPrint(
        "MARK SEEN ERROR: $e",
      );
    }
  }

  /// =========================
  /// DELETE MESSAGE
  /// =========================

  static Future<bool> deleteMessage(
      String messageId) async {
    try {
      await supabase
          .from('messages')
          .delete()
          .eq('id', messageId);

      return true;
    } catch (e) {
      debugPrint(
        "DELETE MESSAGE ERROR: $e",
      );

      return false;
    }
  }

  /// =========================
  /// TYPING
  /// =========================

  static Future<void> setTyping({
    required String receiverId,
    required bool typing,
  }) async {
    try {
      final myId =
          supabase.auth.currentUser!.id;

      await supabase
          .from('profiles')
          .update({
        'typing_to':
        typing
            ? receiverId
            : null,
      })
          .eq(
        'id',
        myId,
      );
    } catch (e) {
      debugPrint(
        "TYPING ERROR: $e",
      );
    }
  }

  /// =========================
  /// TYPING STREAM
  /// =========================

  static Stream<bool> typingStream(
      String otherUserId) {
    final myId =
        supabase.auth.currentUser!.id;

    return supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((profiles) {
      try {
        final profile =
        profiles.firstWhere(
              (p) =>
          p['id'] ==
              otherUserId,
        );

        return profile[
        'typing_to'] ==
            myId;
      } catch (_) {
        return false;
      }
    });
  }

  /// =========================
  /// ONLINE STATUS
  /// =========================

  static Stream<bool> onlineStatus(
      String userId) {
    return supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((profiles) {
      try {
        final profile =
        profiles.firstWhere(
              (p) => p['id'] == userId,
        );

        return profile[
        'is_online'] ==
            true;
      } catch (_) {
        return false;
      }
    });
  }

  /// =========================
  /// UPDATE ONLINE STATUS
  /// =========================

  static Future<void>
  updateOnlineStatus(
      bool online,
      ) async {
    try {
      final myId =
          supabase.auth.currentUser!.id;

      await supabase
          .from('profiles')
          .update({
        'is_online': online,
        'last_seen':
        DateTime.now()
            .toIso8601String(),
      })
          .eq(
        'id',
        myId,
      );
    } catch (e) {
      debugPrint(
        "ONLINE STATUS ERROR: $e",
      );
    }
  }
}