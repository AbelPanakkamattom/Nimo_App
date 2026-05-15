import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService._();

  // =========================================================
  // INSTANCES
  // =========================================================

  static final FlutterLocalNotificationsPlugin notifications =
  FlutterLocalNotificationsPlugin();

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  // =========================================================
  // CHANNEL CONFIGURATION
  // =========================================================

  static const String channelId = 'nimo_messages';
  static const String channelName = 'NIMO Messages';
  static const String channelDescription =
      'Chat and call notifications';

  static bool _initialized = false;

  // =========================================================
  // BACKGROUND HANDLER
  // =========================================================

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message,
      ) async {
    await initialize();
    await _showFromRemoteMessage(message);
  }

  // =========================================================
  // INITIALIZE
  // =========================================================

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // -----------------------------------------------------
      // LOCAL NOTIFICATION SETTINGS
      // -----------------------------------------------------

      const androidSettings =
      AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // -----------------------------------------------------
      // INITIALIZE PLUGIN
      // -----------------------------------------------------

      await notifications.initialize(
        settings: settings,
        onDidReceiveNotificationResponse:
        _onNotificationTapped,
      );

      // -----------------------------------------------------
      // ANDROID CHANNEL
      // -----------------------------------------------------

      final androidPlugin = notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin
            .requestNotificationsPermission();

        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        await androidPlugin
            .createNotificationChannel(channel);
      }

      // -----------------------------------------------------
      // DELAY TO AVOID:
      // Unable to detect current Android Activity
      // -----------------------------------------------------

      await Future.delayed(
        const Duration(seconds: 2),
      );

      // -----------------------------------------------------
      // REQUEST PERMISSIONS
      // -----------------------------------------------------

      await _requestPermissions();

      // -----------------------------------------------------
      // FOREGROUND MESSAGES
      // -----------------------------------------------------

      FirebaseMessaging.onMessage.listen(
            (RemoteMessage message) async {
          await _showFromRemoteMessage(message);
        },
      );

      // -----------------------------------------------------
      // NOTIFICATION OPENED
      // -----------------------------------------------------

      FirebaseMessaging.onMessageOpenedApp.listen(
            (RemoteMessage message) {
          debugPrint(
            'Notification opened: ${message.data}',
          );
        },
      );

      // -----------------------------------------------------
      // APP LAUNCHED FROM NOTIFICATION
      // -----------------------------------------------------

      final initialMessage =
      await _messaging.getInitialMessage();

      if (initialMessage != null) {
        debugPrint(
          'App launched from notification: '
              '${initialMessage.data}',
        );
      }

      _initialized = true;

      debugPrint(
        'NotificationService initialized successfully',
      );
    } catch (e) {
      debugPrint(
        'NOTIFICATION INIT ERROR: $e',
      );
    }
  }

  // =========================================================
  // REQUEST PERMISSIONS
  // =========================================================

  static Future<void> _requestPermissions() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (e) {
      debugPrint(
        'Notification permission error: $e',
      );
    }
  }

  // =========================================================
  // SAVE FCM TOKEN TO SUPABASE
  // =========================================================

  static Future<void> saveTokenToSupabase() async {
    try {
      final user =
          Supabase.instance.client.auth.currentUser;

      if (user == null) return;

      final token = await _messaging.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('FCM token is null');
        return;
      }

      await Supabase.instance.client
          .from('profiles')
          .update({
        'fcm_token': token,
        'updated_at':
        DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      debugPrint('FCM token saved to Supabase');
    } catch (e) {
      debugPrint('SAVE TOKEN ERROR: $e');
    }
  }

  // =========================================================
  // TOKEN REFRESH LISTENER
  // =========================================================

  static void listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen(
          (String newToken) async {
        try {
          final user =
              Supabase.instance.client.auth.currentUser;

          if (user == null) return;

          await Supabase.instance.client
              .from('profiles')
              .update({
            'fcm_token': newToken,
            'updated_at':
            DateTime.now().toIso8601String(),
          }).eq('id', user.id);

          debugPrint('FCM token refreshed');
        } catch (e) {
          debugPrint(
            'TOKEN REFRESH ERROR: $e',
          );
        }
      },
    );
  }

  // =========================================================
  // GET TOKEN
  // =========================================================

  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('GET TOKEN ERROR: $e');
      return null;
    }
  }

  // =========================================================
  // NOTIFICATION TAPPED
  // =========================================================

  static void _onNotificationTapped(
      NotificationResponse response,
      ) {
    debugPrint(
      'Notification tapped. Payload: '
          '${response.payload}',
    );

    if (response.payload != null) {
      try {
        final data =
        jsonDecode(response.payload!);
        debugPrint('Parsed payload: $data');
      } catch (_) {
        // Ignore invalid payload
      }
    }
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
      visibility:
      NotificationVisibility.public,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // =========================================================
  // SHOW REMOTE MESSAGE
  // =========================================================

  static Future<void> _showFromRemoteMessage(
      RemoteMessage message,
      ) async {
    try {
      final notification =
          message.notification;
      final data = message.data;

      final title =
          notification?.title ??
              data['title']?.toString() ??
              'NIMO';

      final body =
          notification?.body ??
              data['body']?.toString() ??
              'New notification';

      final payload =
      data.isNotEmpty
          ? jsonEncode(data)
          : null;

      await showNotification(
        title: title,
        body: body,
        payload: payload,
      );
    } catch (e) {
      debugPrint(
        'SHOW REMOTE MESSAGE ERROR: $e',
      );
    }
  }

  // =========================================================
  // SHOW NOTIFICATION
  // =========================================================

  static Future<void> showNotification({
    required String title,
    required String body,
    int? id,
    String? payload,
  }) async {
    try {
      await initialize();

      final notificationId =
          id ??
              DateTime.now()
                  .millisecondsSinceEpoch
                  .remainder(2147483647);

      await notifications.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: _details,
        payload: payload,
      );
    } catch (e) {
      debugPrint(
        'SHOW NOTIFICATION ERROR: $e',
      );
    }
  }

  // =========================================================
  // MESSAGE NOTIFICATION
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

  static Future<void>
  showMissedCallNotification({
    required String callerName,
    int? id,
    String? payload,
  }) async {
    await showNotification(
      title: 'Missed Call',
      body:
      'You missed a call from $callerName',
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
  // CANCEL SINGLE NOTIFICATION
  // =========================================================

  static Future<void> cancelNotification(
      int id,
      ) async {
    try {
      await notifications.cancel(
        id: id,
      );
    } catch (e) {
      debugPrint(
        'CANCEL NOTIFICATION ERROR: $e',
      );
    }
  }

  // =========================================================
  // CANCEL ALL NOTIFICATIONS
  // =========================================================

  static Future<void>
  cancelAllNotifications() async {
    try {
      await notifications.cancelAll();
    } catch (e) {
      debugPrint(
        'CANCEL ALL NOTIFICATIONS ERROR: $e',
      );
    }
  }
}