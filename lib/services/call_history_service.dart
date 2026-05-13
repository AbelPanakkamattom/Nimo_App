import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/call_model.dart';

class CallHistoryService {
  CallHistoryService._();

  static final SupabaseClient _client = Supabase.instance.client;

  // =========================================================
  // AUTH HELPERS
  // =========================================================

  static User? get currentUser => _client.auth.currentUser;

  static String get myId => currentUser?.id ?? '';

  static bool get isLoggedIn => currentUser != null && myId.isNotEmpty;

  static void _ensureLoggedIn() {
    if (!isLoggedIn) {
      throw Exception('User not logged in.');
    }
  }

  // =========================================================
  // CONTACT + PROFILE LOOKUP
  //
  // Priority:
  // 1. contacts.custom_name (nickname saved by current user)
  // 2. profiles.name
  // 3. profiles.full_name
  // 4. profiles.display_name
  // 5. profiles.username
  // 6. email prefix
  // 7. Unknown User
  // =========================================================

  static Future<Map<String, dynamic>> _getDisplayInfo(
      String otherUserId,
      ) async {
    // Default result
    String displayName = 'Unknown User';
    String? avatarUrl;

    // ---------------------------------------------------------
    // 1) Check contacts.custom_name
    // ---------------------------------------------------------
    try {
      final contact = await _client
          .from('contacts')
          .select('custom_name')
          .eq('user_id', myId)
          .eq('contact_user_id', otherUserId)
          .maybeSingle();

      if (contact != null) {
        final customName =
        (contact['custom_name'] ?? '').toString().trim();

        if (customName.isNotEmpty) {
          displayName = customName;
        }
      }
    } catch (_) {
      // Ignore errors and continue to profile lookup
    }

    // ---------------------------------------------------------
    // 2) Get profile info
    // ---------------------------------------------------------
    try {
      final profile = await _client
          .from('profiles')
          .select(
        '''
            id,
            name,
            full_name,
            display_name,
            username,
            email,
            avatar_url
            ''',
      )
          .eq('id', otherUserId)
          .maybeSingle();

      if (profile != null) {
        // Avatar
        final avatar =
        (profile['avatar_url'] ?? '').toString().trim();
        if (avatar.isNotEmpty) {
          avatarUrl = avatar;
        }

        // If no custom_name was found, use profile fields
        if (displayName == 'Unknown User') {
          final candidates = [
            profile['name'],
            profile['full_name'],
            profile['display_name'],
            profile['username'],
          ];

          for (final value in candidates) {
            final text = (value ?? '').toString().trim();
            if (text.isNotEmpty) {
              displayName = text;
              break;
            }
          }

          // Fallback to email prefix
          if (displayName == 'Unknown User') {
            final email =
            (profile['email'] ?? '').toString().trim();

            if (email.isNotEmpty && email.contains('@')) {
              displayName = email.split('@').first;
            }
          }
        }
      }
    } catch (_) {
      // Ignore profile lookup errors
    }

    return {
      'name': displayName,
      'avatar_url': avatarUrl,
    };
  }

  // =========================================================
  // SAVE CALL
  // =========================================================

  static Future<void> saveCall({
    required String receiverId,
    required String callType, // voice | video
    String status = 'completed',
    int durationSeconds = 0,
    DateTime? startedAt,
    DateTime? endedAt,
  }) async {
    _ensureLoggedIn();

    final receiver = receiverId.trim();

    if (receiver.isEmpty) {
      throw Exception('Receiver ID is empty.');
    }

    final now = DateTime.now();

    await _client.from('calls').insert({
      'caller_id': myId,
      'receiver_id': receiver,
      'call_type': callType,
      'direction': 'outgoing',
      'status': status,
      'duration_seconds': durationSeconds,
      'started_at':
      (startedAt ?? now).toUtc().toIso8601String(),
      'ended_at':
      (endedAt ?? now).toUtc().toIso8601String(),
      'created_at': now.toUtc().toIso8601String(),
    });
  }

  // =========================================================
  // UPDATE CALL
  // =========================================================

  static Future<void> updateCall({
    required String callId,
    String? status,
    int? durationSeconds,
    DateTime? endedAt,
  }) async {
    _ensureLoggedIn();

    final updates = <String, dynamic>{};

    if (status != null && status.trim().isNotEmpty) {
      updates['status'] = status.trim();
    }

    if (durationSeconds != null) {
      updates['duration_seconds'] = durationSeconds;
    }

    if (endedAt != null) {
      updates['ended_at'] =
          endedAt.toUtc().toIso8601String();
    }

    if (updates.isEmpty) return;

    await _client
        .from('calls')
        .update(updates)
        .eq('id', callId);
  }

  // =========================================================
  // BUILD CALL MODEL
  // =========================================================

  static Future<CallModel> _buildCallModel(
      Map<String, dynamic> row,
      ) async {
    final data = Map<String, dynamic>.from(row);

    final callerId =
    (data['caller_id'] ?? '').toString();

    final receiverId =
    (data['receiver_id'] ?? '').toString();

    final isOutgoing = callerId == myId;

    final otherUserId =
    isOutgoing ? receiverId : callerId;

    // Get display info
    final displayInfo =
    await _getDisplayInfo(otherUserId);

    data['other_user_id'] = otherUserId;
    data['other_user_name'] = displayInfo['name'];
    data['other_user_avatar'] =
    displayInfo['avatar_url'];

    return CallModel.fromJson(data);
  }

  // =========================================================
  // GET ALL CALL HISTORY
  // =========================================================

  static Stream<List<CallModel>> getCallHistory() {
    if (!isLoggedIn) {
      return Stream.value([]);
    }

    return _client
        .from('calls')
        .stream(primaryKey: ['id'])
        .order(
      'created_at',
      ascending: false,
    )
        .asyncMap((rows) async {
      final filtered = rows.where((row) {
        final caller =
        (row['caller_id'] ?? '').toString();
        final receiver =
        (row['receiver_id'] ?? '').toString();

        return caller == myId || receiver == myId;
      }).toList();

      final calls = <CallModel>[];

      for (final row in filtered) {
        calls.add(
          await _buildCallModel(
            Map<String, dynamic>.from(row),
          ),
        );
      }

      return calls;
    });
  }

  // =========================================================
  // GET CALL HISTORY WITH SPECIFIC USER
  // =========================================================

  static Stream<List<CallModel>> getCallHistoryWithUser(
      String otherUserId,
      ) {
    if (!isLoggedIn || otherUserId.trim().isEmpty) {
      return Stream.value([]);
    }

    final target = otherUserId.trim();

    return _client
        .from('calls')
        .stream(primaryKey: ['id'])
        .order(
      'created_at',
      ascending: false,
    )
        .asyncMap((rows) async {
      final filtered = rows.where((row) {
        final caller =
        (row['caller_id'] ?? '').toString();
        final receiver =
        (row['receiver_id'] ?? '').toString();

        return (caller == myId &&
            receiver == target) ||
            (caller == target &&
                receiver == myId);
      }).toList();

      final calls = <CallModel>[];

      for (final row in filtered) {
        calls.add(
          await _buildCallModel(
            Map<String, dynamic>.from(row),
          ),
        );
      }

      return calls;
    });
  }

  // =========================================================
  // DELETE ONE CALL
  // =========================================================

  static Future<void> deleteCall(
      String callId,
      ) async {
    _ensureLoggedIn();

    await _client
        .from('calls')
        .delete()
        .eq('id', callId);
  }

  // =========================================================
  // CLEAR ALL CALL HISTORY
  // =========================================================

  static Future<void> clearAllHistory() async {
    _ensureLoggedIn();

    await _client
        .from('calls')
        .delete()
        .or(
      'caller_id.eq.$myId,receiver_id.eq.$myId',
    );
  }
}