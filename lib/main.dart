import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:notification_fcm/api/firebase_api.dart';
import 'package:notification_fcm/firebase_options.dart';
import 'package:notification_fcm/pages/homepage.dart';
import 'package:notification_fcm/pages/notification_page.dart';
import 'package:notification_fcm/theme/app_theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi().initNotification();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const Homepage(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/homepage':
            return _createRoute(const Homepage(), settings);
          case '/notification_page':
            return _createRoute(const NotificationPage(), settings);
          default:
            return null;
        }
      },
    );
  }
}

// Custom page route with animation
PageRoute _createRoute(Widget page, RouteSettings settings) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(opacity: animation, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
