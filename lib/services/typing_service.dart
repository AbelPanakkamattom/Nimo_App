import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TypingService {
  static final SupabaseClient supabase =
      Supabase.instance.client;

  static Timer? _typingTimer;

  /// =========================
  /// CURRENT USER
  /// =========================

  static String get currentUserId =>
      supabase.auth.currentUser?.id ?? '';

  /// =========================
  /// SET TYPING
  /// =========================

  static Future<void> setTyping({
    required String receiverId,
    required bool typing,
  }) async {
    try {
      final myId = currentUserId;

      if (myId.isEmpty) {
        return;
      }

      await supabase
          .from('profiles')
          .update({
        'typing_to':
        typing ? receiverId : '',
        'typing_updated_at':
        DateTime.now()
            .toIso8601String(),
      }).eq('id', myId);
    } catch (e) {
      debugPrint(
        "SET TYPING ERROR: $e",
      );
    }
  }

  /// =========================
  /// START TYPING
  /// =========================

  static Future<void> startTyping({
    required String receiverId,
  }) async {
    try {
      await setTyping(
        receiverId: receiverId,
        typing: true,
      );

      _typingTimer?.cancel();

      _typingTimer = Timer(
        const Duration(seconds: 2),
            () async {
          await stopTyping();
        },
      );
    } catch (e) {
      debugPrint(
        "START TYPING ERROR: $e",
      );
    }
  }

  /// =========================
  /// STOP TYPING
  /// =========================

  static Future<void> stopTyping()
  async {
    try {
      final myId = currentUserId;

      if (myId.isEmpty) {
        return;
      }

      await supabase
          .from('profiles')
          .update({
        'typing_to': '',
        'typing_updated_at':
        DateTime.now()
            .toIso8601String(),
      }).eq('id', myId);
    } catch (e) {
      debugPrint(
        "STOP TYPING ERROR: $e",
      );
    }
  }

  /// =========================
  /// TYPING STREAM
  /// =========================

  static Stream<bool> typingStream({
    required String otherUserId,
  }) {
    final myId = currentUserId;

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

        final typingTo =
        profile['typing_to'];

        return typingTo == myId;
      } catch (_) {
        return false;
      }
    });
  }

  /// =========================
  /// TYPING TEXT
  /// =========================

  static Stream<String> typingText({
    required String otherUserId,
  }) {
    return typingStream(
      otherUserId: otherUserId,
    ).map((typing) {
      if (typing) {
        return "typing...";
      }

      return "";
    });
  }

  /// =========================
  /// DISPOSE
  /// =========================

  static Future<void> dispose()
  async {
    _typingTimer?.cancel();

    await stopTyping();
  }
}