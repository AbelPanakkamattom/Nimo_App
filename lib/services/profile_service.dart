import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  static final SupabaseClient supabase =
      Supabase.instance.client;

  /// =========================
  /// CURRENT USER
  /// =========================

  static User? get currentUser =>
      supabase.auth.currentUser;

  static String get currentUserId =>
      currentUser?.id ?? '';

  /// =========================
  /// GET MY PROFILE
  /// =========================

  static Future<Map<String, dynamic>?>
  getMyProfile() async {
    try {
      final user = currentUser;

      if (user == null) {
        return null;
      }

      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return profile;
    } catch (e) {
      debugPrint(
        "GET PROFILE ERROR: $e",
      );

      return null;
    }
  }

  /// =========================
  /// GET USER PROFILE
  /// =========================

  static Future<Map<String, dynamic>?>
  getUserProfile(
      String userId,
      ) async {
    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return profile;
    } catch (e) {
      debugPrint(
        "GET USER PROFILE ERROR: $e",
      );

      return null;
    }
  }

  /// =========================
  /// PROFILE STREAM
  /// =========================

  static Stream<
      Map<String, dynamic>?>
  profileStream(
      String userId,
      ) {
    return supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((profiles) {
      try {
        return profiles.firstWhere(
              (profile) =>
          profile['id'] ==
              userId,
        );
      } catch (_) {
        return null;
      }
    });
  }

  /// =========================
  /// UPDATE PROFILE
  /// =========================

  static Future<bool> updateProfile({
    required String name,
    String? description,
    String? avatarUrl,
  }) async {
    try {
      final user = currentUser;

      if (user == null) {
        return false;
      }

      await supabase
          .from('profiles')
          .update({
        'name': name.trim(),
        'description':
        description ?? '',
        'avatar_url':
        avatarUrl ?? '',
      }).eq('id', user.id);

      return true;
    } catch (e) {
      debugPrint(
        "UPDATE PROFILE ERROR: $e",
      );

      return false;
    }
  }

  /// =========================
  /// UPDATE ONLINE STATUS
  /// =========================

  static Future<void>
  setOnlineStatus(
      bool online,
      ) async {
    try {
      final user = currentUser;

      if (user == null) {
        return;
      }

      await supabase
          .from('profiles')
          .update({
        'is_online': online,
        'last_seen':
        DateTime.now()
            .toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      debugPrint(
        "ONLINE STATUS ERROR: $e",
      );
    }
  }

  /// =========================
  /// IS ONLINE
  /// =========================

  static bool isOnline(
      Map<String, dynamic>? profile,
      ) {
    if (profile == null) {
      return false;
    }

    return profile['is_online'] ==
        true;
  }

  /// =========================
  /// LAST SEEN TEXT
  /// =========================

  static String getLastSeenText(
      Map<String, dynamic>? profile,
      ) {
    if (profile == null) {
      return "offline";
    }

    final online =
        profile['is_online'] == true;

    if (online) {
      return "online";
    }

    final lastSeen =
    profile['last_seen'];

    if (lastSeen == null) {
      return "offline";
    }

    try {
      final date =
      DateTime.parse(lastSeen)
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
  /// SET TYPING
  /// =========================

  static Future<void> setTyping({
    required String receiverId,
    required bool isTyping,
  }) async {
    try {
      final user = currentUser;

      if (user == null) {
        return;
      }

      await supabase
          .from('profiles')
          .update({
        'typing_to':
        isTyping
            ? receiverId
            : '',
      }).eq('id', user.id);
    } catch (e) {
      debugPrint(
        "SET TYPING ERROR: $e",
      );
    }
  }

  /// =========================
  /// TYPING STREAM
  /// =========================

  static Stream<bool> typingStream(
      String otherUserId,
      ) {
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
  /// BLOCK USER
  /// =========================

  static Future<bool> blockUser(
      String blockedUserId,
      ) async {
    try {
      final user = currentUser;

      if (user == null) {
        return false;
      }

      await supabase
          .from('blocked_users')
          .insert({
        'blocker_id': user.id,
        'blocked_id':
        blockedUserId,
      });

      return true;
    } catch (e) {
      debugPrint(
        "BLOCK USER ERROR: $e",
      );

      return false;
    }
  }

  /// =========================
  /// UNBLOCK USER
  /// =========================

  static Future<bool> unblockUser(
      String blockedUserId,
      ) async {
    try {
      final user = currentUser;

      if (user == null) {
        return false;
      }

      await supabase
          .from('blocked_users')
          .delete()
          .eq(
        'blocker_id',
        user.id,
      )
          .eq(
        'blocked_id',
        blockedUserId,
      );

      return true;
    } catch (e) {
      debugPrint(
        "UNBLOCK USER ERROR: $e",
      );

      return false;
    }
  }

  /// =========================
  /// IS BLOCKED
  /// =========================

  static Future<bool> isBlocked(
      String otherUserId,
      ) async {
    try {
      final user = currentUser;

      if (user == null) {
        return false;
      }

      final data = await supabase
          .from('blocked_users')
          .select()
          .eq(
        'blocker_id',
        user.id,
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

  /// =========================
  /// SEARCH USERS
  /// =========================

  static Future<
      List<Map<String, dynamic>>>
  searchUsers(
      String query,
      ) async {
    try {
      final users = await supabase
          .from('profiles')
          .select()
          .ilike(
        'name',
        '%$query%',
      );

      return List<Map<String,
          dynamic>>.from(users);
    } catch (e) {
      debugPrint(
        "SEARCH USERS ERROR: $e",
      );

      return [];
    }
  }

  /// =========================
  /// USER COUNT
  /// =========================

  static Future<int> totalUsers()
  async {
    try {
      final users = await supabase
          .from('profiles')
          .select();

      return users.length;
    } catch (_) {
      return 0;
    }
  }
}