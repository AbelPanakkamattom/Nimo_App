import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  ProfileService._();

  static final SupabaseClient supabase =
      Supabase.instance.client;

  // =========================================================
  // CONSTANTS
  // =========================================================

  static const String profileTable =
      'profiles';

  static const String avatarBucket =
      'avatarz';

  // =========================================================
  // AUTH HELPERS
  // =========================================================

  static User? get currentUser =>
      supabase.auth.currentUser;

  static String get currentUserId =>
      currentUser?.id ?? '';

  static bool get isLoggedIn =>
      currentUser != null;

  // =========================================================
  // GET MY PROFILE
  // =========================================================

  static Future<Map<String, dynamic>?>
  getMyProfile() async {
    try {
      if (!isLoggedIn) {
        return null;
      }

      final response = await supabase
          .from(profileTable)
          .select()
          .eq('id', currentUserId)
          .maybeSingle();

      if (response == null) {
        await createProfileIfNotExists();

        final retry = await supabase
            .from(profileTable)
            .select()
            .eq('id', currentUserId)
            .maybeSingle();

        if (retry == null) {
          return null;
        }

        return Map<String, dynamic>.from(
          retry,
        );
      }

      return Map<String, dynamic>.from(
        response,
      );
    } catch (e) {
      debugPrint(
        'GET MY PROFILE ERROR: $e',
      );
      return null;
    }
  }

  // =========================================================
  // GET USER PROFILE
  // =========================================================

  static Future<Map<String, dynamic>?>
  getUserProfile(
      String userId,
      ) async {
    try {
      if (userId.trim().isEmpty) {
        return null;
      }

      final response = await supabase
          .from(profileTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Map<String, dynamic>.from(
        response,
      );
    } catch (e) {
      debugPrint(
        'GET USER PROFILE ERROR: $e',
      );
      return null;
    }
  }

  // =========================================================
  // PROFILE STREAM
  // =========================================================

  static Stream<Map<String, dynamic>?>
  profileStream(
      String userId,
      ) {
    if (userId.trim().isEmpty) {
      return Stream.value(null);
    }

    return supabase
        .from(profileTable)
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) {
      if (rows.isEmpty) {
        return null;
      }

      return Map<String, dynamic>.from(
        rows.first,
      );
    });
  }

  // =========================================================
  // CREATE PROFILE
  // =========================================================

  static Future<bool>
  createProfileIfNotExists() async {
    try {
      if (!isLoggedIn) {
        return false;
      }

      final existing = await supabase
          .from(profileTable)
          .select()
          .eq('id', currentUserId)
          .maybeSingle();

      if (existing != null) {
        return true;
      }

      final user = currentUser!;
      final metadata =
          user.userMetadata ?? {};

      final name =
      metadata['name']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true
          ? metadata['name']
          .toString()
          .trim()
          : user.email
          ?.split('@')
          .first ??
          'NIMO User';

      final avatarUrl =
          metadata['avatar_url']
              ?.toString() ??
              '';

      final bio =
          metadata['bio']
              ?.toString() ??
              '';

      final now = DateTime.now()
          .toUtc()
          .toIso8601String();

      await supabase
          .from(profileTable)
          .insert({
        'id': user.id,
        'email': user.email ?? '',
        'name': name,
        'bio': bio,
        'description': bio,
        'avatar_url': avatarUrl,
        'is_online': true,
        'typing_to': '',
        'last_seen': now,
        'updated_at': now,
      });

      return true;
    } catch (e) {
      debugPrint(
        'CREATE PROFILE ERROR: $e',
      );
      return false;
    }
  }

  // =========================================================
  // UPDATE PROFILE
  // =========================================================

  static Future<bool> updateProfile({
    required String name,
    String? bio,
    String? description,
    String? avatarUrl,
  }) async {
    try {
      if (!isLoggedIn) {
        return false;
      }

      final trimmedName =
      name.trim();

      if (trimmedName.isEmpty) {
        return false;
      }

      final current =
      await getMyProfile();

      final finalBio =
      (bio ?? description ?? '')
          .trim();

      final finalAvatar =
      (avatarUrl != null &&
          avatarUrl
              .trim()
              .isNotEmpty)
          ? avatarUrl.trim()
          : current?['avatar_url']
          ?.toString() ??
          '';

      await supabase
          .from(profileTable)
          .upsert({
        'id': currentUserId,
        'email':
        currentUser?.email ?? '',
        'name': trimmedName,
        'bio': finalBio,
        'description': finalBio,
        'avatar_url': finalAvatar,
        'updated_at':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
      });

      await supabase.auth
          .updateUser(
        UserAttributes(
          data: {
            'name': trimmedName,
            'bio': finalBio,
            'avatar_url':
            finalAvatar,
          },
        ),
      );

      return true;
    } catch (e) {
      debugPrint(
        'UPDATE PROFILE ERROR: $e',
      );
      return false;
    }
  }

  // =========================================================
  // UPLOAD AVATAR
  // =========================================================

  static Future<String?> uploadAvatar(
      File file,
      ) async {
    try {
      if (!isLoggedIn) {
        return null;
      }

      final extension =
      p.extension(file.path);

      final path =
          '$currentUserId/${DateTime.now().millisecondsSinceEpoch}$extension';

      await supabase.storage
          .from(avatarBucket)
          .upload(
        path,
        file,
        fileOptions:
        const FileOptions(
          upsert: true,
        ),
      );

      final publicUrl =
      supabase.storage
          .from(
        avatarBucket,
      )
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      debugPrint(
        'UPLOAD AVATAR ERROR: $e',
      );
      return null;
    }
  }

  // =========================================================
  // ONLINE STATUS
  // =========================================================

  static Future<void>
  setOnlineStatus(
      bool online,
      ) async {
    try {
      if (!isLoggedIn) {
        return;
      }

      final now = DateTime.now()
          .toUtc()
          .toIso8601String();

      await supabase
          .from(profileTable)
          .upsert({
        'id': currentUserId,
        'is_online': online,
        'last_seen': now,
        'updated_at': now,
      });
    } catch (e) {
      debugPrint(
        'ONLINE STATUS ERROR: $e',
      );
    }
  }

  static bool isOnline(
      Map<String, dynamic>? profile,
      ) {
    if (profile == null) {
      return false;
    }

    return profile['is_online'] ==
        true;
  }

  // =========================================================
  // LAST SEEN
  // =========================================================

  static String getLastSeenText(
      Map<String, dynamic>? profile,
      ) {
    try {
      if (profile == null) {
        return 'offline';
      }

      if (isOnline(profile)) {
        return 'online';
      }

      final raw =
      profile['last_seen'];

      if (raw == null) {
        return 'offline';
      }

      final lastSeen =
      DateTime.parse(
        raw.toString(),
      ).toLocal();

      final difference =
      DateTime.now()
          .difference(
        lastSeen,
      );

      if (difference.inSeconds <
          60) {
        return 'last seen just now';
      }

      if (difference.inMinutes <
          60) {
        return 'last seen ${difference.inMinutes} min ago';
      }

      if (difference.inHours <
          24) {
        return 'last seen ${difference.inHours} hr ago';
      }

      if (difference.inDays == 1) {
        return 'last seen yesterday';
      }

      return 'last seen ${difference.inDays} days ago';
    } catch (e) {
      debugPrint(
        'LAST SEEN ERROR: $e',
      );
      return 'offline';
    }
  }

  // =========================================================
  // TYPING STATUS
  // =========================================================

  static Future<void> setTyping({
    required String receiverId,
    required bool isTyping,
  }) async {
    try {
      if (!isLoggedIn) {
        return;
      }

      if (receiverId
          .trim()
          .isEmpty) {
        return;
      }

      await supabase
          .from(profileTable)
          .upsert({
        'id': currentUserId,
        'typing_to':
        isTyping
            ? receiverId
            : '',
        'typing_updated_at':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
      });
    } catch (e) {
      debugPrint(
        'SET TYPING ERROR: $e',
      );
    }
  }

  static Stream<bool> typingStream(
      String otherUserId,
      ) {
    if (!isLoggedIn ||
        otherUserId
            .trim()
            .isEmpty) {
      return Stream.value(false);
    }

    return supabase
        .from(profileTable)
        .stream(primaryKey: ['id'])
        .eq('id', otherUserId)
        .map((rows) {
      if (rows.isEmpty) {
        return false;
      }

      final profile =
          rows.first;

      return profile['typing_to'] ==
          currentUserId;
    }).distinct();
  }

  // =========================================================
  // BLOCK USERS
  // =========================================================

  static Future<bool> blockUser(
      String blockedUserId,
      ) async {
    try {
      if (!isLoggedIn) {
        return false;
      }

      await supabase
          .from('blocked_users')
          .upsert({
        'blocker_id':
        currentUserId,
        'blocked_id':
        blockedUserId,
      });

      return true;
    } catch (e) {
      debugPrint(
        'BLOCK USER ERROR: $e',
      );
      return false;
    }
  }

  static Future<bool> unblockUser(
      String blockedUserId,
      ) async {
    try {
      if (!isLoggedIn) {
        return false;
      }

      await supabase
          .from('blocked_users')
          .delete()
          .eq(
        'blocker_id',
        currentUserId,
      )
          .eq(
        'blocked_id',
        blockedUserId,
      );

      return true;
    } catch (e) {
      debugPrint(
        'UNBLOCK USER ERROR: $e',
      );
      return false;
    }
  }

  static Future<bool> isBlocked(
      String otherUserId,
      ) async {
    try {
      if (!isLoggedIn) {
        return false;
      }

      final result =
      await supabase
          .from(
        'blocked_users',
      )
          .select()
          .eq(
        'blocker_id',
        currentUserId,
      )
          .eq(
        'blocked_id',
        otherUserId,
      )
          .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint(
        'IS BLOCKED ERROR: $e',
      );
      return false;
    }
  }

  // =========================================================
  // SEARCH USERS
  // =========================================================

  static Future<
      List<Map<String, dynamic>>>
  searchUsers(
      String query,
      ) async {
    try {
      final trimmed =
      query.trim();

      if (trimmed.isEmpty) {
        return [];
      }

      final response =
      await supabase
          .from(profileTable)
          .select()
          .ilike(
        'name',
        '%$trimmed%',
      )
          .neq(
        'id',
        currentUserId,
      )
          .limit(50);

      return List<
          Map<String,
              dynamic>>.from(
        response,
      );
    } catch (e) {
      debugPrint(
        'SEARCH USERS ERROR: $e',
      );
      return [];
    }
  }

  // =========================================================
  // TOTAL USERS
  // =========================================================

  static Future<int>
  totalUsers() async {
    try {
      final response =
      await supabase
          .from(profileTable)
          .select('id');

      return response.length;
    } catch (e) {
      debugPrint(
        'TOTAL USERS ERROR: $e',
      );
      return 0;
    }
  }

  // =========================================================
  // PROFILE STATISTICS
  // =========================================================

  static Future<int>
  getCallCount() async {
    try {
      if (!isLoggedIn) {
        return 0;
      }

      final response =
      await supabase
          .from('calls')
          .select('id')
          .or(
        'caller_id.eq.$currentUserId,receiver_id.eq.$currentUserId',
      );

      return response.length;
    } catch (e) {
      debugPrint(
        'GET CALL COUNT ERROR: $e',
      );
      return 0;
    }
  }

  static Future<int>
  getChatCount() async {
    try {
      if (!isLoggedIn) {
        return 0;
      }

      final response =
      await supabase
          .from('messages')
          .select(
        'sender_id, receiver_id',
      )
          .or(
        'sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId',
      );

      final Set<String>
      chatUsers = {};

      for (final row in response) {
        final senderId =
            row['sender_id']
                ?.toString() ??
                '';

        final receiverId =
            row['receiver_id']
                ?.toString() ??
                '';

        if (senderId ==
            currentUserId) {
          if (receiverId
              .isNotEmpty) {
            chatUsers.add(
              receiverId,
            );
          }
        } else if (receiverId ==
            currentUserId) {
          if (senderId
              .isNotEmpty) {
            chatUsers.add(
              senderId,
            );
          }
        }
      }

      return chatUsers.length;
    } catch (e) {
      debugPrint(
        'GET CHAT COUNT ERROR: $e',
      );
      return 0;
    }
  }

  static Future<int>
  getMediaCount() async {
    try {
      if (!isLoggedIn) {
        return 0;
      }

      final response =
      await supabase
          .from('messages')
          .select('id, type')
          .or(
        'sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId',
      )
          .inFilter(
        'type',
        [
          'image',
          'video',
          'document',
          'audio',
        ],
      );

      return response.length;
    } catch (e) {
      debugPrint(
        'GET MEDIA COUNT ERROR: $e',
      );
      return 0;
    }
  }

  static Future<Map<String, int>>
  getProfileStats() async {
    try {
      final results =
      await Future.wait([
        getChatCount(),
        getCallCount(),
        getMediaCount(),
      ]);

      return {
        'chats': results[0],
        'calls': results[1],
        'media': results[2],
      };
    } catch (e) {
      debugPrint(
        'GET PROFILE STATS ERROR: $e',
      );

      return {
        'chats': 0,
        'calls': 0,
        'media': 0,
      };
    }
  }
}