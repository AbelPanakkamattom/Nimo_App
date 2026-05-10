import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnlineService {
  OnlineService._();

  static final SupabaseClient supabase =
      Supabase.instance.client;

  static Timer? _heartbeatTimer;

  /// Update online status every 30 seconds while app is active.
  static const Duration heartbeatInterval =
  Duration(seconds: 30);

  // ==========================================
  // CURRENT USER
  // ==========================================

  static String get currentUserId =>
      supabase.auth.currentUser?.id ?? '';

  static bool get isLoggedIn =>
      currentUserId.isNotEmpty;

  // ==========================================
  // SET ONLINE
  // ==========================================

  static Future<void> setOnline() async {
    if (!isLoggedIn) return;

    try {
      await supabase
          .from('profiles')
          .update({
        'is_online': true,
        'last_seen':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
      })
          .eq('id', currentUserId);

      _startHeartbeat();
    } catch (e) {
      debugPrint(
        'SET ONLINE ERROR: $e',
      );
    }
  }

  // ==========================================
  // SET OFFLINE
  // ==========================================

  static Future<void> setOffline() async {
    _stopHeartbeat();

    if (!isLoggedIn) return;

    try {
      await supabase
          .from('profiles')
          .update({
        'is_online': false,
        'last_seen':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
      })
          .eq('id', currentUserId);
    } catch (e) {
      debugPrint(
        'SET OFFLINE ERROR: $e',
      );
    }
  }

  // ==========================================
  // HEARTBEAT
  // ==========================================

  static void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(
      heartbeatInterval,
          (_) async {
        if (!isLoggedIn) {
          _stopHeartbeat();
          return;
        }

        try {
          await supabase
              .from('profiles')
              .update({
            'is_online': true,
            'last_seen':
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
            'ONLINE HEARTBEAT ERROR: $e',
          );
        }
      },
    );
  }

  static void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // ==========================================
  // USER STATUS STREAM
  // ==========================================

  static Stream<
      Map<String, dynamic>>
  userStatusStream(
      String userId,
      ) {
    if (userId.trim().isEmpty) {
      return Stream.value({
        'online': false,
        'last_seen': null,
      });
    }

    return supabase
        .from('profiles')
        .stream(
      primaryKey: ['id'],
    )
        .eq('id', userId)
        .map((profiles) {
      try {
        if (profiles.isEmpty) {
          return {
            'online': false,
            'last_seen': null,
          };
        }

        final profile =
            profiles.first;

        return {
          'online':
          profile['is_online'] ==
              true,
          'last_seen':
          profile['last_seen'],
        };
      } catch (e) {
        debugPrint(
          'STATUS STREAM ERROR: $e',
        );

        return {
          'online': false,
          'last_seen': null,
        };
      }
    });
  }

  // ==========================================
  // SIMPLE ONLINE STREAM
  // ==========================================

  static Stream<bool> isOnlineStream(
      String userId,
      ) {
    return userStatusStream(
      userId,
    ).map(
          (data) =>
      data['online'] == true,
    );
  }

  // ==========================================
  // LAST SEEN
  // ==========================================

  static Future<DateTime?>
  getLastSeen(
      String userId,
      ) async {
    if (userId.trim().isEmpty) {
      return null;
    }

    try {
      final result =
      await supabase
          .from('profiles')
          .select(
        'last_seen',
      )
          .eq('id', userId)
          .maybeSingle();

      final value =
      result?['last_seen'];

      if (value == null) {
        return null;
      }

      return DateTime.parse(
        value.toString(),
      ).toLocal();
    } catch (e) {
      debugPrint(
        'GET LAST SEEN ERROR: $e',
      );
      return null;
    }
  }

  // ==========================================
  // DISPOSE
  // ==========================================

  static Future<void> dispose() async {
    _stopHeartbeat();
  }
}