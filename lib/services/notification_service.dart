import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  // =========================================================
  // PLUGIN
  // =========================================================

  static final FlutterLocalNotificationsPlugin notifications =
  FlutterLocalNotificationsPlugin();

  // =========================================================
  // CHANNEL INFO
  // =========================================================

  static const String channelId = 'nimo_messages';
  static const String channelName = 'NIMO Messages';
  static const String channelDescription =
      'Chat message notifications';

  static bool _initialized = false;

  // =========================================================
  // INITIALIZE
  // =========================================================

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Android initialization
      const androidSettings =
      AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await notifications.initialize(
        settings,
        onDidReceiveNotificationResponse:
        _onNotificationTapped,
      );

      // Android-specific setup
      final androidImplementation =
      notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // Request Android 13+ notification permission
      await androidImplementation
          ?.requestNotificationsPermission();

      // Create notification channel
      const channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await androidImplementation
          ?.createNotificationChannel(channel);

      _initialized = true;
    } catch (e) {
      debugPrint('NOTIFICATION INIT ERROR: $e');
    }
  }

  // =========================================================
  // TAP HANDLER
  // =========================================================

  static void _onNotificationTapped(
      NotificationResponse response,
      ) {
    debugPrint(
      'Notification tapped. Payload: ${response.payload}',
    );
    // You can add navigation logic here later.
  }

  // =========================================================
  // NOTIFICATION DETAILS
  // =========================================================

  static const NotificationDetails _details =
  NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: 'NIMO',
      visibility: NotificationVisibility.public,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // =========================================================
  // SHOW GENERIC NOTIFICATION
  // =========================================================

  static Future<void> showNotification({
    required String title,
    required String body,
    int? id,
    String? payload,
  }) async {
    try {
      await initialize();

      final notificationId = id ??
          DateTime.now()
              .millisecondsSinceEpoch
              .remainder(2147483647);

      await notifications.show(
        notificationId,
        title,
        body,
        _details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('SHOW NOTIFICATION ERROR: $e');
    }
  }

  // =========================================================
  // CHAT MESSAGE NOTIFICATION
  // =========================================================

  static Future<void> showMessageNotification({
    required String senderName,
    required String message,
    int? id,
    String? payload,
  }) async {
    await showNotification(
      title: senderName,
      body: message,
      id: id,
      payload: payload,
    );
  }

  // =========================================================
  // MEDIA NOTIFICATION
  // =========================================================

  static Future<void> showMediaNotification({
    required String senderName,
    required String type,
    int? id,
    String? payload,
  }) async {
    await showNotification(
      title: senderName,
      body: 'Sent a $type',
      id: id,
      payload: payload,
    );
  }

  // =========================================================
  // MISSED CALL NOTIFICATION
  // =========================================================

  static Future<void> showMissedCallNotification({
    required String callerName,
    int? id,
    String? payload,
  }) async {
    await showNotification(
      title: 'Missed Call',
      body: 'You missed a call from $callerName',
      id: id,
      payload: payload,
    );
  }

  // =========================================================
  // TYPING NOTIFICATION
  // =========================================================

  static Future<void> showTypingNotification({
    required String name,
    int? id,
    String? payload,
  }) async {
    await showNotification(
      title: name,
      body: 'typing...',
      id: id,
      payload: payload,
    );
  }

  // =========================================================
  // CANCEL ONE
  // =========================================================

  static Future<void> cancelNotification(int id) async {
    try {
      await notifications.cancel(id);
    } catch (e) {
      debugPrint('CANCEL NOTIFICATION ERROR: $e');
    }
  }

  // =========================================================
  // CANCEL ALL
  // =========================================================

  static Future<void> cancelAllNotifications() async {
    try {
      await notifications.cancelAll();
    } catch (e) {
      debugPrint('CANCEL ALL NOTIFICATIONS ERROR: $e');
    }
  }
}