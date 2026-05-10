import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TypingService {
  TypingService._();

  static final SupabaseClient supabase =
      Supabase.instance.client;

  static Timer? _typingTimer;

  /// Typing indicator remains valid for 5 seconds.
  static const Duration typingTimeout =
  Duration(seconds: 5);

  // ==========================================
  // CURRENT USER
  // ==========================================

  static String get currentUserId =>
      supabase.auth.currentUser?.id ?? '';

  static bool get isLoggedIn =>
      currentUserId.isNotEmpty;

  // ==========================================
  // SET TYPING STATUS
  // ==========================================

  static Future<void> setTyping({
    required String receiverId,
    required bool typing,
  }) async {
    if (!isLoggedIn ||
        receiverId.trim().isEmpty) {
      return;
    }

    try {
      await supabase
          .from('profiles')
          .update({
        'typing_to':
        typing
            ? receiverId
            : '',
        'typing_updated_at':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
      })
          .eq(
        'id',
        currentUserId,
      );
    } catch (e) {
      debugPrint(
        'SET TYPING ERROR: $e',
      );
    }
  }

  // ==========================================
  // START TYPING
  // ==========================================

  static Future<void> startTyping({
    required String receiverId,
  }) async {
    if (!isLoggedIn ||
        receiverId.trim().isEmpty) {
      return;
    }

    try {
      await setTyping(
        receiverId: receiverId,
        typing: true,
      );

      _typingTimer?.cancel();

      _typingTimer = Timer(
        typingTimeout,
            () async {
          await stopTyping();
        },
      );
    } catch (e) {
      debugPrint(
        'START TYPING ERROR: $e',
      );
    }
  }

  // ==========================================
  // STOP TYPING
  // ==========================================

  static Future<void> stopTyping() async {
    if (!isLoggedIn) {
      _typingTimer?.cancel();
      _typingTimer = null;
      return;
    }

    try {
      _typingTimer?.cancel();
      _typingTimer = null;

      await supabase
          .from('profiles')
          .update({
        'typing_to': '',
        'typing_updated_at':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
      })
          .eq(
        'id',
        currentUserId,
      );
    } catch (e) {
      debugPrint(
        'STOP TYPING ERROR: $e',
      );
    }
  }

  // ==========================================
  // CHECK IF TIMESTAMP IS STILL VALID
  // ==========================================

  static bool _isTypingStillValid(
      dynamic updatedAt,
      ) {
    if (updatedAt == null) {
      return false;
    }

    try {
      final timestamp =
      DateTime.parse(
        updatedAt.toString(),
      ).toUtc();

      final now =
      DateTime.now().toUtc();

      return now.difference(
        timestamp,
      ) <=
          typingTimeout;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // TYPING STREAM
  // ==========================================

  static Stream<bool> typingStream({
    required String otherUserId,
  }) {
    if (!isLoggedIn ||
        otherUserId.trim().isEmpty) {
      return Stream.value(false);
    }

    return supabase
        .from('profiles')
        .stream(
      primaryKey: ['id'],
    )
        .eq(
      'id',
      otherUserId,
    )
        .map((profiles) {
      try {
        if (profiles.isEmpty) {
          return false;
        }

        final profile =
            profiles.first;

        final typingTo =
        profile['typing_to'];

        final updatedAt =
        profile[
        'typing_updated_at'];

        if (typingTo !=
            currentUserId) {
          return false;
        }

        return _isTypingStillValid(
          updatedAt,
        );
      } catch (e) {
        debugPrint(
          'TYPING STREAM ERROR: $e',
        );
        return false;
      }
    })
        .distinct();
  }

  // ==========================================
  // TYPING TEXT STREAM
  // ==========================================

  static Stream<String> typingText({
    required String otherUserId,
  }) {
    return typingStream(
      otherUserId: otherUserId,
    ).map(
          (isTyping) =>
      isTyping
          ? 'typing...'
          : '',
    );
  }

  // ==========================================
  // DISPOSE
  // ==========================================

  static Future<void> dispose() async {
    try {
      _typingTimer?.cancel();
      _typingTimer = null;

      if (isLoggedIn) {
        await stopTyping();
      }
    } catch (e) {
      debugPrint(
        'TYPING DISPOSE ERROR: $e',
      );
    }
  }
}