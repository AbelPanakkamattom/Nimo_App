import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
  notifications =
  FlutterLocalNotificationsPlugin();

  /// =========================
  /// INIT
  /// =========================

  static Future<void> initialize()
  async {
    try {
      const AndroidInitializationSettings
      androidSettings =
      AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const InitializationSettings
      settings =
      InitializationSettings(
        android: androidSettings,
      );

      await notifications.initialize(
        settings,
      );
    } catch (e) {
      debugPrint(
        "NOTIFICATION INIT ERROR: $e",
      );
    }
  }

  /// =========================
  /// SHOW SIMPLE NOTIFICATION
  /// =========================

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    try {
      const AndroidNotificationDetails
      androidDetails =
      AndroidNotificationDetails(
        'nimo_messages',
        'Nimo Messages',
        channelDescription:
        'Chat message notifications',
        importance:
        Importance.max,
        priority: Priority.high,
        playSound: true,
      );

      const NotificationDetails
      details =
      NotificationDetails(
        android: androidDetails,
      );

      await notifications.show(
        DateTime.now()
            .millisecondsSinceEpoch,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint(
        "SHOW NOTIFICATION ERROR: $e",
      );
    }
  }

  /// =========================
  /// NEW MESSAGE
  /// =========================

  static Future<void>
  showMessageNotification({
    required String senderName,
    required String message,
  }) async {
    await showNotification(
      title: senderName,
      body: message,
    );
  }

  /// =========================
  /// MISSED CALL
  /// =========================

  static Future<void>
  showMissedCallNotification({
    required String callerName,
  }) async {
    await showNotification(
      title: "Missed Call",
      body:
      "You missed a call from $callerName",
    );
  }

  /// =========================
  /// FILE RECEIVED
  /// =========================

  static Future<void>
  showMediaNotification({
    required String senderName,
    required String type,
  }) async {
    await showNotification(
      title: senderName,
      body: "Sent a $type",
    );
  }

  /// =========================
  /// TYPING NOTIFICATION
  /// =========================

  static Future<void>
  showTypingNotification({
    required String name,
  }) async {
    await showNotification(
      title: name,
      body: "typing...",
    );
  }

  /// =========================
  /// CANCEL ALL
  /// =========================

  static Future<void>
  cancelAllNotifications()
  async {
    try {
      await notifications.cancelAll();
    } catch (e) {
      debugPrint(
        "CANCEL NOTIFICATION ERROR: $e",
      );
    }
  }

  /// =========================
  /// CANCEL ONE
  /// =========================

  static Future<void>
  cancelNotification(int id)
  async {
    try {
      await notifications.cancel(id);
    } catch (e) {
      debugPrint(
        "CANCEL SINGLE ERROR: $e",
      );
    }
  }
}