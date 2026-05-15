import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/message_model.dart';

class SupabaseChatService {
  SupabaseChatService._();

  static final SupabaseClient _client =
      Supabase.instance.client;

  // =========================================================
  // AUTH HELPERS
  // =========================================================

  static User? get currentUser =>
      _client.auth.currentUser;

  static String get myId =>
      currentUser?.id ?? '';

  static bool get isLoggedIn =>
      currentUser != null &&
          myId.isNotEmpty;

  static void _ensureLoggedIn() {
    if (!isLoggedIn) {
      throw Exception(
        'User not logged in.',
      );
    }
  }

  // =========================================================
  // GET STORAGE BUCKET BY FOLDER
  // =========================================================

  static String _getBucketName(
      String folder,
      ) {
    final normalized =
    folder.toLowerCase();

    switch (normalized) {
      case 'images':
      case 'image':
      case 'photos':
      case 'photo':
        return 'message';

      case 'videos':
      case 'video':
        return 'videos';

      case 'documents':
      case 'document':
      case 'files':
      case 'file':
        return 'documents';

      case 'audio':
      case 'voice':
      case 'voices':
        return 'audio';

      default:
        return 'message';
    }
  }

  // =========================================================
  // UPLOAD FILE TO SUPABASE STORAGE
  // =========================================================

  static Future<String> uploadFile({
    required File file,
    required String folder,
  }) async {
    _ensureLoggedIn();

    try {
      final bucket =
      _getBucketName(folder);

      final extension =
      path.extension(file.path);

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}$extension';

      final storagePath =
          '$myId/$folder/$fileName';

      await _client.storage
          .from(bucket)
          .upload(
        storagePath,
        file,
        fileOptions:
        const FileOptions(
          upsert: true,
        ),
      );

      final publicUrl =
      _client.storage
          .from(bucket)
          .getPublicUrl(
        storagePath,
      );

      debugPrint(
        'UPLOAD SUCCESS: $publicUrl',
      );

      return publicUrl;
    } catch (e) {
      debugPrint(
        'UPLOAD FILE ERROR: $e',
      );
      throw Exception(
        'Failed to upload file.',
      );
    }
  }

  // =========================================================
  // SEND MESSAGE
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
    String? callStatus,
    int? callDuration,
  }) async {
    _ensureLoggedIn();

    final receiver =
    receiverId.trim();
    final text = content.trim();

    if (receiver.isEmpty) {
      throw Exception(
        'Receiver ID is empty.',
      );
    }

    final blocked =
    await isBlocked(receiver);

    if (blocked) {
      throw Exception(
        'You have blocked this user.',
      );
    }

    final hasText =
        text.isNotEmpty;
    final hasMedia =
        mediaUrl != null &&
            mediaUrl
                .trim()
                .isNotEmpty;
    final isCallMessage =
        type == 'call' ||
            type ==
                'video_call';

    if (!hasText &&
        !hasMedia &&
        !isCallMessage) {
      throw Exception(
        'Message is empty.',
      );
    }

    final now = DateTime.now()
        .toUtc()
        .toIso8601String();

    final payload =
    <String, dynamic>{
      'sender_id': myId,
      'receiver_id': receiver,
      'content':
      hasText ? text : '',
      'type': type,
      'message_type': type,
      'status':
      MessageStatus
          .sent
          .name,
      'deleted': false,
      'is_seen': false,
      'created_at': now,
      'updated_at': now,
    };

    if (replyToMessageId != null &&
        replyToMessageId
            .trim()
            .isNotEmpty) {
      payload['reply_to'] =
          replyToMessageId
              .trim();
    }

    if (hasMedia) {
      payload['media_url'] =
          mediaUrl.trim();
      payload['file_url'] =
          mediaUrl.trim();
    }

    if (fileName != null &&
        fileName
            .trim()
            .isNotEmpty) {
      payload['file_name'] =
          fileName.trim();
    }

    if (fileSize != null) {
      payload['file_size'] =
          fileSize;
    }

    if (mimeType != null &&
        mimeType
            .trim()
            .isNotEmpty) {
      payload['mime_type'] =
          mimeType.trim();
    }

    if (isCallMessage) {
      payload['call_status'] =
      (callStatus != null &&
          callStatus
              .trim()
              .isNotEmpty)
          ? callStatus.trim()
          : 'completed';

      payload['call_duration'] =
          callDuration ?? 0;
    }

    try {
      await _client
          .from('messages')
          .insert(payload);

      debugPrint(
        'MESSAGE SENT: $type',
      );
    } on PostgrestException catch (e) {
      debugPrint(
        'SEND MESSAGE ERROR: ${e.message}',
      );
      throw Exception(
        e.message,
      );
    } catch (e) {
      debugPrint(
        'SEND MESSAGE ERROR: $e',
      );
      throw Exception(
        'Failed to send message.',
      );
    }
  }

  // =========================================================
  // CHAT STREAM
  // =========================================================

  static Stream<List<Message>>
  getChat(String otherUserId) {
    if (!isLoggedIn ||
        otherUserId
            .trim()
            .isEmpty) {
      return Stream.value(
        <Message>[],
      );
    }

    return _client
        .from('messages')
        .stream(
      primaryKey: ['id'],
    )
        .order('created_at')
        .map((rows) {
      try {
        final messages = rows
            .where((row) {
          final sender =
              row['sender_id']
                  ?.toString() ??
                  '';
          final receiver =
              row['receiver_id']
                  ?.toString() ??
                  '';

          return (sender ==
              myId &&
              receiver ==
                  otherUserId) ||
              (sender ==
                  otherUserId &&
                  receiver ==
                      myId);
        })
            .map(
              (row) =>
              Message.fromJson(
                Map<String,
                    dynamic>.from(
                  row,
                ),
              ),
        )
            .toList();

        messages.sort(
              (a, b) => a
              .createdAt
              .compareTo(
            b.createdAt,
          ),
        );

        _autoMarkDelivered(
          messages,
          otherUserId,
        );

        _autoMarkSeen(
          messages,
          otherUserId,
        );

        return messages;
      } catch (e) {
        debugPrint(
          'GET CHAT ERROR: $e',
        );
        return <Message>[];
      }
    });
  }

  // =========================================================
  // DELIVERY STATUS
  // =========================================================

  static Future<void>
  markAsDelivered(
      String otherUserId,
      ) async {
    if (!isLoggedIn) return;

    try {
      await _client
          .from('messages')
          .update({
        'status':
        MessageStatus
            .delivered
            .name,
        'updated_at':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
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
        MessageStatus
            .sent
            .name,
      );
    } catch (e) {
      debugPrint(
        'MARK DELIVERED ERROR: $e',
      );
    }
  }

  static Future<void>
  markAsSeen(
      String otherUserId,
      ) async {
    if (!isLoggedIn) return;

    try {
      await _client
          .from('messages')
          .update({
        'status':
        MessageStatus
            .seen
            .name,
        'is_seen': true,
        'seen_at':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
        'updated_at':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
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
        MessageStatus
            .seen
            .name,
      );
    } catch (e) {
      debugPrint(
        'MARK SEEN ERROR: $e',
      );
    }
  }

  static void _autoMarkDelivered(
      List<Message> messages,
      String otherUserId,
      ) {
    final hasPending =
    messages.any(
          (message) =>
      message.senderId ==
          otherUserId &&
          message.receiverId ==
              myId &&
          message.status ==
              MessageStatus.sent,
    );

    if (hasPending) {
      markAsDelivered(
        otherUserId,
      );
    }
  }

  static void _autoMarkSeen(
      List<Message> messages,
      String otherUserId,
      ) {
    final hasUnseen =
    messages.any(
          (message) =>
      message.senderId ==
          otherUserId &&
          message.receiverId ==
              myId &&
          message.status !=
              MessageStatus.seen,
    );

    if (hasUnseen) {
      markAsSeen(
        otherUserId,
      );
    }
  }

  // =========================================================
  // DELETE MESSAGE
  // =========================================================

  static Future<void>
  deleteMessage(
      String messageId,
      ) async {
    try {
      await _client
          .from('messages')
          .delete()
          .eq('id', messageId);
    } catch (_) {
      throw Exception(
        'Failed to delete message.',
      );
    }
  }

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
        'updated_at':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
      })
          .eq('id', messageId);
    } catch (e) {
      debugPrint(
        'DELETE FOR EVERYONE ERROR: $e',
      );
    }
  }

  // =========================================================
  // BLOCK USER
  // =========================================================

  static Future<void> blockUser({
    required String blockedId,
  }) async {
    if (!isLoggedIn ||
        blockedId
            .trim()
            .isEmpty) {
      return;
    }

    try {
      await _client
          .from('blocked_users')
          .upsert({
        'blocker_id': myId,
        'blocked_id': blockedId,
      });
    } catch (e) {
      debugPrint(
        'BLOCK USER ERROR: $e',
      );
    }
  }

  static Future<void>
  unblockUser(
      String blockedId,
      ) async {
    if (!isLoggedIn ||
        blockedId
            .trim()
            .isEmpty) {
      return;
    }

    try {
      await _client
          .from('blocked_users')
          .delete()
          .match({
        'blocker_id': myId,
        'blocked_id': blockedId,
      });
    } catch (e) {
      debugPrint(
        'UNBLOCK USER ERROR: $e',
      );
    }
  }

  static Future<bool>
  isBlocked(
      String otherUserId,
      ) async {
    if (!isLoggedIn ||
        otherUserId
            .trim()
            .isEmpty) {
      return false;
    }

    try {
      final result =
      await _client
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

      return result != null;
    } catch (_) {
      return false;
    }
  }
}