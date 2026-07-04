// lib/core/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_service.dart';

/// Handles FCM token registration, foreground/background message handling
class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseService.messaging;

  /// Initialize FCM notification handling
  static Future<void> initialize() async {
    // Request notification permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check for initial message (app opened from terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Subscribe to topics
    await _messaging.subscribeToTopic('all_users');
  }

  /// Get the current FCM token
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Listen for token refresh
  static Stream<String> onTokenRefresh() {
    return _messaging.onTokenRefresh;
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    // In-app notification can be shown here using a snackbar/overlay
  }

  /// Handle notification tap (background/terminated)
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    // Navigate to appropriate screen based on message type
    final type = message.data['type'] ?? '';
    switch (type) {
      case 'redeemApproved':
      case 'redeemRejected':
        // Navigate to redeem page
        break;
      case 'referralReward':
        // Navigate to profile page
        break;
      default:
        // Navigate to notifications page
        break;
    }
  }

  /// Subscribe user to a specific topic
  static Future<void> subscribeTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}
