import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import 'supabase_chat_service.dart';

class ZegoCallService {
  // ==========================================================
  // ZEGO CONFIGURATION
  // ==========================================================

  static const int appID = 1302064610;

  static const String appSign =
      '58106cd5873417be720d8e2ceade88a850f9b0f2d09079b005236d878a915898';

  static const String token =
      '04AAAAAGoHf2YADE01AD+pGNk3C5WQGQCyfON0NLWhk4ik0GePN9ap3ItmMYq0A2Cd6KlJZ0zvLdnxd5FI3peJucFG27oeGjo+ltFTGjV9vbZ7b1pHlxG/XVkNJZW9lobEFUsXs/qgwGR+6VhFgkK99RtRHSYu6ekbdwVmHhdqtLUg56bfQo1KYhoNca2LbsKKll9WkK+f4WzQGw03MIYl25Y+6GIQmJ93uzGbEFcKpDxuQLsC95BLXXLy0koQ9HXbiLMiUKzomg1VpAE=';

  static const String resourceID = 'zego_data';

  // ==========================================================
  // NAVIGATOR KEY
  // ==========================================================

  static final GlobalKey<NavigatorState>
  navigatorKey =
  GlobalKey<NavigatorState>();

  // ==========================================================
  // STATE
  // ==========================================================

  static bool _initialized = false;
  static String? _currentZegoUserID;

  static String? _targetUserId;
  static bool _isVideoCall = false;
  static DateTime? _callStartTime;

  // Prevent duplicate save operations
  static bool _callFinalized = false;

  // ==========================================================
  // GETTERS
  // ==========================================================

  static bool get isInitialized =>
      _initialized;

  // ==========================================================
  // CONVERT UUID TO ZEGO SAFE ID
  // ==========================================================

  static String toZegoUserID(
      String userID,
      ) {
    final cleaned =
    userID.replaceAll('-', '').trim();

    if (cleaned.isEmpty) {
      throw Exception('User ID is empty');
    }

    final shortID =
    cleaned.length >= 8
        ? cleaned.substring(0, 8)
        : cleaned;

    return 'u_$shortID';
  }

  // ==========================================================
  // REGISTER PLUGINS
  // ==========================================================

  static void registerPlugins() {
    ZegoUIKitPrebuiltCallInvitationService()
        .setNavigatorKey(
      navigatorKey,
    );
  }

  // ==========================================================
  // INITIALIZE
  // ==========================================================

  static Future<void> init({
    required String userID,
    required String userName,
  }) async {
    final zegoUserID =
    toZegoUserID(userID);

    if (_initialized &&
        _currentZegoUserID ==
            zegoUserID) {
      return;
    }

    if (_initialized &&
        _currentZegoUserID !=
            zegoUserID) {
      uninit();
    }

    try {
      registerPlugins();

      await ZegoUIKitPrebuiltCallInvitationService()
          .init(
        appID: appID,
        appSign: appSign,
        userID: zegoUserID,
        userName: userName,
        token: token,
        plugins: [
          ZegoUIKitSignalingPlugin(),
        ],
        events:
        ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (
              ZegoCallEndEvent event,
              VoidCallback defaultAction,
              ) async {
            try {
              await _completeCurrentCall();
            } catch (e) {
              developer.log(
                'Error saving completed call',
                error: e,
              );
            }

            defaultAction();
          },
        ),
        invitationEvents:
        ZegoUIKitPrebuiltCallInvitationEvents(
          onOutgoingCallTimeout: (
              String callID,
              List<ZegoCallUser> callees,
              bool isVideoCall,
              ) async {
            await _markMissed();
          },
          onOutgoingCallDeclined: (
              String callID,
              ZegoCallUser callee,
              String reason,
              ) async {
            await _markRejected();
          },
          onIncomingCallTimeout: (
              String callID,
              ZegoCallUser caller,
              ) async {
            await _markMissed();
          },
        ),
        requireConfig: (
            ZegoCallInvitationData data,
            ) {
          final isVideo =
              data.type ==
                  ZegoCallInvitationType
                      .videoCall;

          final config = isVideo
              ? ZegoUIKitPrebuiltCallConfig
              .oneOnOneVideoCall()
              : ZegoUIKitPrebuiltCallConfig
              .oneOnOneVoiceCall();

          config.turnOnCameraWhenJoining =
              isVideo;
          config.turnOnMicrophoneWhenJoining =
          true;

          return config;
        },
      );

      _initialized = true;
      _currentZegoUserID =
          zegoUserID;

      developer.log(
        'ZEGO initialized successfully',
      );
    } catch (e, stackTrace) {
      _initialized = false;
      _currentZegoUserID = null;

      developer.log(
        'ZEGO initialization failed',
        error: e,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ==========================================================
  // UNINITIALIZE
  // ==========================================================

  static void uninit() {
    if (!_initialized) {
      return;
    }

    try {
      ZegoUIKitPrebuiltCallInvitationService()
          .uninit();
    } catch (_) {}

    _initialized = false;
    _currentZegoUserID = null;
    _resetCurrentCall();
  }

  // ==========================================================
  // START VOICE CALL
  // ==========================================================

  static Future<void> startVoiceCall({
    required String targetUserID,
    required String targetUserName,
  }) async {
    await _startCall(
      targetUserID: targetUserID,
      targetUserName:
      targetUserName,
      isVideo: false,
    );
  }

  // ==========================================================
  // START VIDEO CALL
  // ==========================================================

  static Future<void> startVideoCall({
    required String targetUserID,
    required String targetUserName,
  }) async {
    await _startCall(
      targetUserID: targetUserID,
      targetUserName:
      targetUserName,
      isVideo: true,
    );
  }

  // ==========================================================
  // START CALL
  // ==========================================================

  static Future<void> _startCall({
    required String targetUserID,
    required String targetUserName,
    required bool isVideo,
  }) async {
    if (!_initialized) {
      throw Exception(
        'ZegoCallService is not initialized',
      );
    }

    final trimmedTargetId =
    targetUserID.trim();

    if (trimmedTargetId.isEmpty) {
      throw Exception(
        'Target user ID is empty',
      );
    }

    final zegoTargetUserID =
    toZegoUserID(
      trimmedTargetId,
    );

    if (_currentZegoUserID ==
        zegoTargetUserID) {
      throw Exception(
        'You cannot call yourself',
      );
    }

    _resetCurrentCall();

    _targetUserId =
        trimmedTargetId;
    _isVideoCall = isVideo;
    _callStartTime =
        DateTime.now();
    _callFinalized = false;

    // Show call bubble immediately
    await _saveChatMessage(
      status: 'ringing',
      durationSeconds: 0,
    );

    await Future.delayed(
      const Duration(
        milliseconds: 500,
      ),
    );

    await ZegoUIKitPrebuiltCallInvitationService()
        .send(
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

    developer.log(
      'Call invitation sent',
    );
  }

  // ==========================================================
  // COMPLETE CALL
  // ==========================================================

  static Future<void>
  _completeCurrentCall() async {
    if (_targetUserId == null ||
        _callFinalized) {
      return;
    }

    _callFinalized = true;

    final durationSeconds =
    _callStartTime == null
        ? 0
        : DateTime.now()
        .difference(
      _callStartTime!,
    )
        .inSeconds;

    await _saveCallRecord(
      status: 'completed',
      durationSeconds:
      durationSeconds,
    );

    await _saveChatMessage(
      status: 'completed',
      durationSeconds:
      durationSeconds,
    );

    developer.log(
      'Call completed: $durationSeconds sec',
    );

    _resetCurrentCall();
  }

  // ==========================================================
  // MISSED CALL
  // ==========================================================

  static Future<void> _markMissed() async {
    if (_targetUserId == null ||
        _callFinalized) {
      return;
    }

    _callFinalized = true;

    await _saveCallRecord(
      status: 'missed',
      durationSeconds: 0,
    );

    await _saveChatMessage(
      status: 'missed',
      durationSeconds: 0,
    );

    developer.log('Call missed');

    _resetCurrentCall();
  }

  // ==========================================================
  // REJECTED CALL
  // ==========================================================

  static Future<void>
  _markRejected() async {
    if (_targetUserId == null ||
        _callFinalized) {
      return;
    }

    _callFinalized = true;

    await _saveCallRecord(
      status: 'rejected',
      durationSeconds: 0,
    );

    await _saveChatMessage(
      status: 'rejected',
      durationSeconds: 0,
    );

    developer.log('Call rejected');

    _resetCurrentCall();
  }

  // ==========================================================
  // SAVE CALL RECORD
  // ==========================================================

  static Future<void> _saveCallRecord({
    required String status,
    required int durationSeconds,
  }) async {
    if (_targetUserId == null) {
      return;
    }

    final supabase =
        Supabase.instance.client;

    final currentUser =
        supabase.auth.currentUser;

    if (currentUser == null) {
      return;
    }

    final callerId =
        currentUser.id;
    final receiverId =
    _targetUserId!;

    final callType =
    _isVideoCall
        ? 'video'
        : 'voice';

    await supabase
        .from('calls')
        .insert({
      'caller_id': callerId,
      'receiver_id': receiverId,
      'call_type': callType,
      'status': status,
      'duration_seconds':
      durationSeconds,
    });

    developer.log(
      'Call record saved',
    );
  }

  // ==========================================================
  // SAVE CHAT MESSAGE
  // ==========================================================

  static Future<void> _saveChatMessage({
    required String status,
    required int durationSeconds,
  }) async {
    if (_targetUserId == null) {
      return;
    }

    String content;

    if (status == 'missed') {
      content = _isVideoCall
          ? 'Missed video call'
          : 'Missed voice call';
    } else if (status ==
        'rejected') {
      content = _isVideoCall
          ? 'Rejected video call'
          : 'Rejected voice call';
    } else if (status ==
        'completed') {
      content = _isVideoCall
          ? 'Completed video call'
          : 'Completed voice call';
    } else {
      content = _isVideoCall
          ? 'Outgoing video call'
          : 'Outgoing voice call';
    }

    await SupabaseChatService
        .sendMessage(
      receiverId:
      _targetUserId!,
      content: content,
      type: _isVideoCall
          ? 'video_call'
          : 'call',
      callStatus: status,
      callDuration:
      durationSeconds,
    );
  }

  // ==========================================================
  // RESET CURRENT CALL
  // ==========================================================

  static void _resetCurrentCall() {
    _targetUserId = null;
    _isVideoCall = false;
    _callStartTime = null;
    _callFinalized = false;
  }
}