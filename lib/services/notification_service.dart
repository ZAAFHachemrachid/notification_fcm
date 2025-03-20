import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize android notification settings
    const androidInitialize =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize iOS notification settings
    const DarwinInitializationSettings iOSInitialize =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Complete initialization
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitialize,
      iOS: iOSInitialize,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      // Handle notification tap
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );
  }

  // Show local notification
  static Future<void> showNotification(RemoteMessage message) async {
    try {
      // Android notification details
      final androidDetails = AndroidNotificationDetails(
        'firebase_push', // channel id
        'Firebase Push Notifications', // channel name
        channelDescription: 'Channel for Firebase push notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        enableLights: true,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFFF8C00), // Firebase theme color
      );

      // iOS notification details
      const iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Notification details for all platforms
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      // Show the notification
      await _notificationsPlugin.show(
        message.hashCode, // unique notification ID
        message.notification?.title ?? 'New Notification',
        message.notification?.body,
        details,
        payload: message.data.toString(),
      );

      debugPrint('✅ Local notification shown successfully');
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
