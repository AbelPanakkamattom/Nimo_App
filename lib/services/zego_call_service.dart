import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class ZegoCallService {
  /// Your ZEGOCLOUD AppID
  static const int appID = 1302064610;

  /// Replace with your real AppSign from ZEGOCLOUD console
  static const String appSign = '58106cd5873417be720d8e2ceade88a850f9b0f2d09079b005236d878a915898';

  static bool _initialized = false;

  // ===============================================================
  // INITIALIZE
  // ===============================================================
  static void init({
    required String userID,
    required String userName,
  }) {
    if (_initialized) return;

    ZegoUIKitPrebuiltCallInvitationService().init(
      appID: appID,
      appSign: appSign,
      userID: userID,
      userName: userName,
      plugins: [ZegoUIKitSignalingPlugin()],
      requireConfig: (ZegoCallInvitationData data) {
        final isVideo =
            data.type == ZegoCallInvitationType.videoCall;

        final config = isVideo
            ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

        config.turnOnCameraWhenJoining = isVideo;

        return config;
      },
    );

    _initialized = true;
  }

  // ===============================================================
  // UNINITIALIZE
  // ===============================================================
  static void uninit() {
    if (!_initialized) return;

    ZegoUIKitPrebuiltCallInvitationService().uninit();
    _initialized = false;
  }

  // ===============================================================
  // START VOICE CALL
  // ===============================================================
  static void startVoiceCall({
    required String targetUserID,
    required String targetUserName,
  }) {
    _startCall(
      targetUserID: targetUserID,
      targetUserName: targetUserName,
      isVideo: false,
    );
  }

  // ===============================================================
  // START VIDEO CALL
  // ===============================================================
  static void startVideoCall({
    required String targetUserID,
    required String targetUserName,
  }) {
    _startCall(
      targetUserID: targetUserID,
      targetUserName: targetUserName,
      isVideo: true,
    );
  }

  // ===============================================================
  // INTERNAL CALL METHOD
  // ===============================================================
  static void _startCall({
    required String targetUserID,
    required String targetUserName,
    required bool isVideo,
  }) {
    if (!_initialized) {
      throw Exception(
        'ZegoCallService is not initialized. '
            'Call ZegoCallService.init() after login.',
      );
    }

    ZegoUIKitPrebuiltCallInvitationService().send(
      invitees: [
        ZegoCallUser(
          targetUserID,
          targetUserName,
        ),
      ],
      isVideoCall: isVideo,
      resourceID: 'nimo_call',
    );
  }
}