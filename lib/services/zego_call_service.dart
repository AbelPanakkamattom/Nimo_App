import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import 'call_history_service.dart';
import 'supabase_chat_service.dart';

class ZegoCallService {
  // ===============================================================
  // ZEGO CONFIGURATION
  // ===============================================================

  static const int appID = 1302064610;

  static const String appSign =
      '58106cd5873417be720d8e2ceade88a850f9b0f2d09079b005236d878a915898';

  /// Replace this token whenever it expires.
  static const String token =
      '04AAAAAGoFqMsADGYEeinZKQELmN9C3wCz71NcTSKHXLldVahjJXmNceGOVGb0aoJ4vMMhV6EMnLvTFwiXOj+eUdnIAU7/b7wlhst1+Z7BfiWMqwTA8mCtQTl93xAuY8ePteDwt2UjarMGejqZrCWUgV8ofUEdwRkro+zBn0d+T3TynvtHp+gjP7LclN+KMPAMz2q2/MChWKNSpjVOHR1pUkVJzvkaFOcrkjX3xoFuO9pnsU9BFBGMa1BDM78bN1vgozQxZ8Z+WPKlcSMB';

  /// Must match ZEGO Console Resource ID.
  static const String resourceID = 'zego_data';

  // ===============================================================
  // NAVIGATOR KEY
  // ===============================================================

  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  // ===============================================================
  // INTERNAL STATE
  // ===============================================================

  static bool _initialized = false;
  static String? _currentZegoUserID;

  // ===============================================================
  // GETTERS
  // ===============================================================

  static bool get isInitialized => _initialized;

  // ===============================================================
  // CONVERT USER ID TO ZEGO SAFE USER ID
  // ===============================================================

  static String toZegoUserID(String userID) {
    final cleaned = userID.replaceAll('-', '').trim();

    if (cleaned.isEmpty) {
      throw Exception('User ID is empty.');
    }

    final shortID =
    cleaned.length >= 8 ? cleaned.substring(0, 8) : cleaned;

    return 'u_$shortID';
  }

  // ===============================================================
  // REGISTER PLUGINS
  // ===============================================================

  static void registerPlugins() {
    ZegoUIKitPrebuiltCallInvitationService()
        .setNavigatorKey(navigatorKey);
  }

  // ===============================================================
  // INITIALIZE ZEGO
  // ===============================================================

  static Future<void> init({
    required String userID,
    required String userName,
  }) async {
    final zegoUserID = toZegoUserID(userID);

    // Already initialized for this user
    if (_initialized && _currentZegoUserID == zegoUserID) {
      return;
    }

    // Different user logged in
    if (_initialized && _currentZegoUserID != zegoUserID) {
      uninit();
    }

    try {
      registerPlugins();

      developer.log(
        'Initializing ZEGO for $userName ($zegoUserID)',
      );

      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: appID,
        appSign: appSign,
        userID: zegoUserID,
        userName: userName,
        token: token,
        plugins: [
          ZegoUIKitSignalingPlugin(),
        ],
        requireConfig: (ZegoCallInvitationData data) {
          final isVideo =
              data.type == ZegoCallInvitationType.videoCall;

          final config = isVideo
              ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
              : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

          config.turnOnCameraWhenJoining = isVideo;
          config.turnOnMicrophoneWhenJoining = true;

          return config;
        },
      );

      _initialized = true;
      _currentZegoUserID = zegoUserID;

      developer.log('ZEGO initialized successfully.');
    } catch (e, stackTrace) {
      _initialized = false;
      _currentZegoUserID = null;

      developer.log(
        'ZEGO initialization failed.',
        error: e,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ===============================================================
  // UNINITIALIZE ZEGO
  // ===============================================================

  static void uninit() {
    if (!_initialized) {
      return;
    }

    try {
      ZegoUIKitPrebuiltCallInvitationService().uninit();
    } catch (_) {
      // Ignore cleanup errors
    } finally {
      _initialized = false;
      _currentZegoUserID = null;
    }
  }

  // ===============================================================
  // START VOICE CALL
  // ===============================================================

  static Future<void> startVoiceCall({
    required String targetUserID,
    required String targetUserName,
  }) async {
    await _startCall(
      targetUserID: targetUserID,
      targetUserName: targetUserName,
      isVideo: false,
    );
  }

  // ===============================================================
  // START VIDEO CALL
  // ===============================================================

  static Future<void> startVideoCall({
    required String targetUserID,
    required String targetUserName,
  }) async {
    await _startCall(
      targetUserID: targetUserID,
      targetUserName: targetUserName,
      isVideo: true,
    );
  }

  // ===============================================================
  // INTERNAL START CALL METHOD
  // ===============================================================

  static Future<void> _startCall({
    required String targetUserID,
    required String targetUserName,
    required bool isVideo,
  }) async {
    if (!_initialized) {
      throw Exception('ZegoCallService is not initialized.');
    }

    final trimmedTargetId = targetUserID.trim();

    if (trimmedTargetId.isEmpty) {
      throw Exception('Target user ID is empty.');
    }

    final zegoTargetUserID = toZegoUserID(trimmedTargetId);

    if (_currentZegoUserID == zegoTargetUserID) {
      throw Exception('You cannot call yourself.');
    }

    // Give ZEGO signaling some time to connect.
    await Future.delayed(const Duration(seconds: 3));

    developer.log(
      'Sending ${isVideo ? 'video' : 'voice'} call '
          'to $targetUserName ($zegoTargetUserID)',
    );

    // ===========================================================
    // SEND ZEGO CALL INVITATION
    // ===========================================================

    await ZegoUIKitPrebuiltCallInvitationService().send(
      invitees: [
        ZegoCallUser(
          zegoTargetUserID,
          targetUserName,
        ),
      ],
      isVideoCall: isVideo,
      resourceID: resourceID,
      timeoutSeconds: 60,
    );

    developer.log('Call invitation sent successfully.');

    // ===========================================================
    // SAVE TO CALLS TABLE (for Calls tab)
    // ===========================================================

    try {
      await CallHistoryService.saveCall(
        receiverId: trimmedTargetId,
        callType: isVideo ? 'video' : 'voice',
        status: 'completed',
        durationSeconds: 0,
      );

      developer.log('Call record saved to calls table.');
    } catch (e, stackTrace) {
      developer.log(
        'Failed to save call record to calls table.',
        error: e,
        stackTrace: stackTrace,
      );
    }

    // ===========================================================
    // SAVE TO MESSAGES TABLE (for chat call bubbles)
    // ===========================================================

    try {
      await SupabaseChatService.sendMessage(
        receiverId: trimmedTargetId,
        content: isVideo
            ? 'Outgoing video call'
            : 'Outgoing voice call',
        type: isVideo ? 'video_call' : 'call',
        callStatus: 'completed',
        callDuration: 0,
      );

      developer.log('Call message saved to messages table.');
    } catch (e, stackTrace) {
      developer.log(
        'Failed to save call message to messages table.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}