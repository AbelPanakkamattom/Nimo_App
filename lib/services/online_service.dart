import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnlineService {
  static final SupabaseClient supabase =
      Supabase.instance.client;

  static Timer? _heartbeatTimer;

  /// =========================
  /// CURRENT USER
  /// =========================

  static String? get currentUserId =>
      supabase.auth.currentUser?.id;

  /// =========================
  /// SET ONLINE
  /// =========================

  static Future<void> setOnline(
      bool online,
      ) async {
    try {
      final userId = currentUserId;

      if (userId == null) {
        return;
      }

      await supabase
          .from('profiles')
          .update({
        'is_online': online,
        'last_seen':
        DateTime.now()
            .toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint(
        "SET ONLINE ERROR: $e",
      );
    }
  }

  /// =========================
  /// START HEARTBEAT
  /// =========================

  static void startHeartbeat() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 20),
          (_) async {
        await refreshOnline();
      },
    );
  }

  /// =========================
  /// STOP HEARTBEAT
  /// =========================

  static void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// =========================
  /// REFRESH ONLINE
  /// =========================

  static Future<void>
  refreshOnline() async {
    try {
      final userId = currentUserId;

      if (userId == null) {
        return;
      }

      await supabase
          .from('profiles')
          .update({
        'is_online': true,
        'last_seen':
        DateTime.now()
            .toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint(
        "REFRESH ONLINE ERROR: $e",
      );
    }
  }

  /// =========================
  /// USER ONLINE STREAM
  /// =========================

  static Stream<bool> onlineStream(
      String userId,
      ) {
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
  /// LAST SEEN STREAM
  /// =========================

  static Stream<String>
  lastSeenStream(
      String userId,
      ) {
    return supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((profiles) {
      try {
        final profile =
        profiles.firstWhere(
              (p) => p['id'] == userId,
        );

        final online =
            profile['is_online'] ==
                true;

        if (online) {
          return "online";
        }

        final lastSeen =
        profile['last_seen'];

        if (lastSeen == null) {
          return "offline";
        }

        return formatLastSeen(
          lastSeen,
        );
      } catch (_) {
        return "offline";
      }
    });
  }

  /// =========================
  /// FORMAT LAST SEEN
  /// =========================

  static String formatLastSeen(
      String time,
      ) {
    try {
      final date =
      DateTime.parse(time)
          .toLocal();

      final now = DateTime.now();

      final difference =
      now.difference(date);

      if (difference.inSeconds <
          60) {
        return "last seen just now";
      }

      if (difference.inMinutes <
          60) {
        return "last seen ${difference.inMinutes} min ago";
      }

      if (difference.inHours < 24) {
        return "last seen ${difference.inHours} hr ago";
      }

      return "last seen ${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return "offline";
    }
  }

  /// =========================
  /// TYPING STATUS
  /// =========================

  static Future<void> setTyping({
    required String receiverId,
    required bool typing,
  }) async {
    try {
      final userId = currentUserId;

      if (userId == null) {
        return;
      }

      await supabase
          .from('profiles')
          .update({
        'typing_to':
        typing ? receiverId : '',
      }).eq('id', userId);
    } catch (e) {
      debugPrint(
        "TYPING ERROR: $e",
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

        return profile[
        'typing_to'] ==
            myId;
      } catch (_) {
        return false;
      }
    });
  }

  /// =========================
  /// APP START
  /// =========================

  static Future<void> start()
  async {
    await setOnline(true);

    startHeartbeat();
  }

  /// =========================
  /// APP CLOSE
  /// =========================

  static Future<void> stop()
  async {
    stopHeartbeat();

    await setOnline(false);
  }
}