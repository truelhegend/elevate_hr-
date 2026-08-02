import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          // Send token to server
        }

        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          // Update token on server
        });
      }

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    } catch (e) {
      // Notification setup failed, continue without push notifications
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background message
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Navigate to appropriate screen
  }

  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (_) {}
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (_) {}
  }
}
