import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:notification_fcm/main.dart';
import 'package:notification_fcm/services/notification_service.dart';

class FirebaseApi {
  // create an instance of Firebase Messaging
  final _firebaseMessaging = FirebaseMessaging.instance;

  // function to handle background messages
  @pragma('vm:entry-point')
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Background message received:');
    debugPrint('  ID: ${message.messageId}');
    debugPrint('  Title: ${message.notification?.title}');
    debugPrint('  Body: ${message.notification?.body}');
    debugPrint('  Data: ${message.data}');
  }

  // function to initialize notification
  Future<void> initNotification() async {
    try {
      // Initialize local notifications
      await NotificationService.initialize();

      // request permission for notification
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

      // Initialize background message handler first
      FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

      // fetch the FCM token for this device
      final fCMToken = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token: $fCMToken');

      // Initialize push notification handlers
      await initPushNotification();
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  // function to handle received messages
  void handleMessage(RemoteMessage? message) {
    // check if the message is null
    if (message == null) return;

    debugPrint('🔔 Handling message:');
    debugPrint('  ID: ${message.messageId}');
    debugPrint('  Title: ${message.notification?.title}');
    debugPrint('  Body: ${message.notification?.body}');
    debugPrint('  Data: ${message.data}');

    // navigate to new screen when message is received and user taps on it
    try {
      navigatorKey.currentState?.pushNamed(
        '/notification_page',
        arguments: message,
      );
      debugPrint('✅ Navigation successful');
    } catch (e) {
      debugPrint('❌ Navigation failed: $e');
    }
  }

  // function to initialize foreground and background settings
  Future<void> initPushNotification() async {
    // Handle message when app is terminated and opened from notification
    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          '🔔 App opened from terminated state with message: ${initialMessage.messageId}',
        );
        handleMessage(initialMessage);
      }

      // Handle message when app is in background and opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint(
          '🔔 App opened from background state with message: ${message.messageId}',
        );
        handleMessage(message);
      });

      // Handle message when app is in foreground
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('🔔 Received foreground message: ${message.messageId}');
        // Show local notification when app is in foreground
        NotificationService.showNotification(message);
        handleMessage(message);
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
}
