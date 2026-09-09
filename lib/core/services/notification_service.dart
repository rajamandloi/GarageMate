import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      _debug('FCM permission: ${settings.authorizationStatus}');
      await getToken();

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        // Never log or persist FCM tokens in plaintext logs. The caller can
        // send the token directly to the authenticated backend when needed.
        if (newToken.isNotEmpty) _debug('FCM token refreshed.');
      });

      FirebaseMessaging.onMessage.listen((message) {
        // Notification content may contain customer information; do not log it.
        _debug('FCM foreground message received.');
      });
    } catch (_) {
      _debug('FCM initialization failed.');
    }
  }

  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (_) {
      _debug('FCM token request failed.');
      return null;
    }
  }

  static void _debug(String message) {
    if (kDebugMode) debugPrint('GarageMate: $message');
  }
}
