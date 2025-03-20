import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:notification_fcm/main.dart';
import 'package:notification_fcm/pages/chat_detail_page.dart';
import 'package:notification_fcm/services/notification_service.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  String? currentToken;

  // Handle background messages
  @pragma('vm:entry-point')
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Background message received:');
    debugPrint('  ID: ${message.messageId}');
    debugPrint('  Title: ${message.notification?.title}');
    debugPrint('  Body: ${message.notification?.body}');
    debugPrint('  Data: ${message.data}');
  }

  // Initialize notifications
  Future<void> initNotification() async {
    try {
      // Initialize local notifications
      await NotificationService.initialize();

      // Request permission for notifications
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        announcement: false,
        carPlay: false,
      );

      debugPrint('🔔 User notification settings:');
      debugPrint('  Alert: ${settings.alert}');
      debugPrint('  Badge: ${settings.badge}');
      debugPrint('  Sound: ${settings.sound}');

      // Initialize background message handler
      FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

      // Get FCM token
      currentToken = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token: $currentToken');

      // Initialize push notifications
      await initPushNotification();
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  // Handle message
  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    debugPrint('🔔 Handling message:');
    debugPrint('  ID: ${message.messageId}');
    debugPrint('  Title: ${message.notification?.title}');
    debugPrint('  Body: ${message.notification?.body}');
    debugPrint('  Data: ${message.data}');

    // Navigate based on message type
    try {
      if (message.data['type'] == 'chat') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ChatDetailPage(
              currentUserId: message.data['receiverId'],
              otherUserId: message.data['senderId'],
            ),
          ),
        );
      } else {
        navigatorKey.currentState?.pushNamed(
          '/notification_page',
          arguments: message,
        );
      }
      debugPrint('✅ Navigation successful');
    } catch (e) {
      debugPrint('❌ Navigation failed: $e');
    }
  }

  // Initialize push notification handlers
  Future<void> initPushNotification() async {
    try {
      // Handle terminated state
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          '🔔 App opened from terminated state with message: ${initialMessage.messageId}',
        );
        handleMessage(initialMessage);
      }

      // Handle background state
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint(
          '🔔 App opened from background state with message: ${message.messageId}',
        );
        handleMessage(message);
      });

      // Handle foreground state
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('🔔 Received foreground message: ${message.messageId}');
        NotificationService.showNotification(message);
      });

      // Set foreground notification presentation options
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('❌ Error setting up push notifications: $e');
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // Get current token
  String? getToken() => currentToken;
}
