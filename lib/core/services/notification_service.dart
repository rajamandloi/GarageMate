import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/services/screens/service_details_screen.dart';
import '../../features/customers/screens/customer_details_screen.dart';
import '../../features/reminders/screens/reminders_screen.dart';
import '../../main.dart';

// ============================================================
// BACKGROUND HANDLER
// ============================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  debugPrint(
    'Background FCM message: ${message.messageId}',
  );
}

// ============================================================
// NOTIFICATION SERVICE
// ============================================================

class NotificationService {
  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'garagemate_notifications';
  static const String _channelName = 'GarageMate Notifications';
  static const String _channelDescription =
      'Notifications for reminders, payments, and updates';

  // ============================================================
  // INITIALIZE
  // ============================================================

  static Future<void> initialize() async {
    // --------------------------------------------------------
    // 1. Request permission
    // --------------------------------------------------------
    await _requestPermission();

    // --------------------------------------------------------
    // 2. Setup local notifications
    // --------------------------------------------------------
    await _setupLocalNotifications();

    // --------------------------------------------------------
    // 3. Foreground message handler
    // --------------------------------------------------------
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // --------------------------------------------------------
    // 4. Background message handler
    // --------------------------------------------------------
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    // --------------------------------------------------------
    // 5. When user taps notification (app in background)
    // --------------------------------------------------------
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // --------------------------------------------------------
    // 6. When app opened from terminated state via notification
    // --------------------------------------------------------
    final initialMessage =
        await _messaging.getInitialMessage();

    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    debugPrint('✅ NotificationService initialized');
  }

  // ============================================================
  // REQUEST PERMISSION
  // ============================================================

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
      'FCM permission: ${settings.authorizationStatus}',
    );
  }

  // ============================================================
  // SETUP LOCAL NOTIFICATIONS
  // ============================================================

  static Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create Android channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ============================================================
  // HANDLE FOREGROUND MESSAGE
  // ============================================================

  static void _handleForegroundMessage(
    RemoteMessage message,
  ) {
    debugPrint(
      'Foreground FCM: ${message.notification?.title}',
    );

    final notification = message.notification;

    if (notification == null) return;

    // Show local notification
    _showLocalNotification(
      title: notification.title ?? 'GarageMate',
      body: notification.body ?? '',
      payload: message.data.toString(),
    );
  }

  // ============================================================
  // SHOW LOCAL NOTIFICATION
  // ============================================================

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // ============================================================
  // HANDLE NOTIFICATION TAP (FCM)
  // ============================================================

  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');

    final data = message.data;

    _navigateFromNotification(
      type: data['type'],
      id: data['id'],
    );
  }

  // ============================================================
  // HANDLE LOCAL NOTIFICATION TAP
  // ============================================================

  static void _onLocalNotificationTap(
    NotificationResponse response,
  ) {
    debugPrint(
      'Local notification tapped: ${response.payload}',
    );

    // Payload could be JSON string; parse if needed
    // For now, just navigate to reminders
    _navigateFromNotification(
      type: 'reminder',
      id: null,
    );
  }

  // ============================================================
  // NAVIGATE FROM NOTIFICATION
  // ============================================================

  static void _navigateFromNotification({
    String? type,
    String? id,
  }) {
    final navigator = navigatorKey.currentState;

    if (navigator == null) return;

    switch (type) {
      case 'reminder':
        navigator.push(
          MaterialPageRoute(
            builder: (_) => const RemindersScreen(),
          ),
        );
        break;

      case 'service':
        // Could fetch service by id and navigate to detail
        // For now, go to services list
        navigator.push(
          MaterialPageRoute(
            builder: (_) => const RemindersScreen(),
          ),
        );
        break;

      case 'customer':
        navigator.push(
          MaterialPageRoute(
            builder: (_) => const RemindersScreen(),
          ),
        );
        break;

      default:
        navigator.push(
          MaterialPageRoute(
            builder: (_) => const RemindersScreen(),
          ),
        );
    }
  }

  // ============================================================
  // GET FCM TOKEN
  // ============================================================

  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('FCM token error: $e');
      return null;
    }
  }

  // ============================================================
  // SUBSCRIBE TO TOPIC
  // ============================================================

  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}