import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class ZegoCallService {
  // ===============================================================
  // ZEGO CONFIGURATION
  // ===============================================================
  static const int appID = 1302064610;

  static const String appSign =
      '58106cd5873417be720d8e2ceade88a850f9b0f2d09079b005236d878a915898';

  /// IMPORTANT:
  /// This temporary token is valid for 24 hours only.
  /// When it expires, generate a new one from ZEGO Token Tools
  /// and replace this value.
  static const String token =
      '04AAAAAGoFBcEADO7eABp7Fk8RntvREAC0yqjwGKfKg9lIE4pJf9UujAtn0b3n8EfxWAVrPB8h/kGYyC1JSwistdXlho3tj/i6OhoigmG9kMG5knHIy7YG+6Dzl7CKCbcV3/kwPUvORenmOhgofnvjxkbt0bKlu/XZ7zhr+Vx1pZoLvSQTGCrkvhtNZJU+eX6Frh+TgwDKk7Z9IEI/+EhtzyLIScORK9yfAEhNkMMPrgPDQN2L/W49EaPN+Y8PLMwM8teDBPg/zzUcOugNAQ==';

  /// Must match the Resource ID configured in ZEGO Console.
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
  // PUBLIC STATUS
  // ===============================================================
  static bool get isInitialized => _initialized;

  // ===============================================================
  // CONVERT USER ID TO ZEGO-SAFE ID
  //
  // Supabase UUID:
  // 48a7e79a-2714-4700-812f-9a653e557928
  //
  // ZEGO-safe ID:
  // u_48a7e79a
  //
  // ZEGO has a user ID length limit.
  // ===============================================================
  static String toZegoUserID(String userID) {
    final cleaned = userID.replaceAll('-', '').trim();

    if (cleaned.isEmpty) {
      throw Exception('User ID is empty.');
    }

    // Use only the first 8 characters to stay within ZEGO limits.
    final shortID =
    cleaned.length >= 8 ? cleaned.substring(0, 8) : cleaned;

    return 'u_$shortID';
  }

  // ===============================================================
  // REGISTER NAVIGATOR KEY
  // ===============================================================
  static void registerPlugins() {
    ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(
      navigatorKey,
    );
  }

  // ===============================================================
  // INITIALIZE ZEGO
  // ===============================================================
  static Future<void> init({
    required String userID,
    required String userName,
  }) async {
    final zegoUserID = toZegoUserID(userID);

    // Already initialized for same user
    if (_initialized && _currentZegoUserID == zegoUserID) {
      return;
    }

    // Different user logged in -> reset
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
  // INTERNAL CALL METHOD
  // ===============================================================
  static Future<void> _startCall({
    required String targetUserID,
    required String targetUserName,
    required bool isVideo,
  }) async {
    if (!_initialized) {
      throw Exception('ZegoCallService is not initialized.');
    }

    if (targetUserID.trim().isEmpty) {
      throw Exception('Target user ID is empty.');
    }

    final zegoTargetUserID = toZegoUserID(targetUserID);

    if (_currentZegoUserID == zegoTargetUserID) {
      throw Exception('You cannot call yourself.');
    }

    // Give signaling a moment to ensure connection is established.
    await Future.delayed(const Duration(seconds: 3));

    developer.log(
      'Sending ${isVideo ? 'video' : 'voice'} call '
          'to $targetUserName ($zegoTargetUserID)',
    );

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
  }
}