import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification_fcm/main.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null) {
          // Handle notification tap
          navigatorKey.currentState?.pushNamed('/notification_page');
        }
      },
    );
  }

  static Future<void> showNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final android = message.notification?.android;
      final data = message.data;

      if (notification == null) return;

      // Create notification channel for chat messages
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'chat_messages',
              'Chat Messages',
              description: 'Notifications for chat messages',
              importance: Importance.high,
            ),
          );

      // Determine notification type from data
      final isChat = data['type'] == 'chat';
      final channelId = isChat ? 'chat_messages' : 'default_channel';

      // Create notification details
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          isChat ? 'Chat Messages' : 'Notifications',
          channelDescription: isChat
              ? 'Notifications for chat messages'
              : 'General notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: android?.smallIcon,
          styleInformation: BigTextStyleInformation(
            notification.body ?? '',
            htmlFormatBigText: true,
            contentTitle: notification.title,
            htmlFormatContentTitle: true,
            summaryText: isChat ? 'New message' : 'Notification',
            htmlFormatSummaryText: true,
          ),
        ),
      );

      // Show notification
      await _notificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: isChat ? data['chatId'] : null,
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
