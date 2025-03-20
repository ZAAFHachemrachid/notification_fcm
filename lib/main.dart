import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notification_fcm/api/firebase_api.dart';
import 'package:notification_fcm/auth/auth_service.dart';
import 'package:notification_fcm/auth/login_page.dart';
import 'package:notification_fcm/firebase_options.dart';
import 'package:notification_fcm/pages/homepage.dart';
import 'package:notification_fcm/pages/notification_page.dart';
import 'package:notification_fcm/theme/app_theme.dart';
import 'package:provider/provider.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    debugPrint('🚀 Starting app initialization...');
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('✅ Flutter binding initialized');

    debugPrint('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('✅ Firebase initialized successfully');
    debugPrint('📱 Platform: ${defaultTargetPlatform.toString()}');
    debugPrint(
        '🔧 Firebase Options: ${DefaultFirebaseOptions.currentPlatform.toString()}');

    debugPrint('🔔 Initializing Firebase API...');
    await FirebaseApi().initNotification();
    debugPrint('✅ Firebase API initialized successfully');

    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('❌ Error during initialization: $e');
    debugPrint('📚 Stack trace: $stackTrace');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AuthWrapper(),
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
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: context.read<AuthService>().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          debugPrint('❌ Auth stream error: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        if (snapshot.hasData) {
          debugPrint('✅ User is authenticated');
          return const Homepage();
        }

        debugPrint('👤 User is not authenticated');
        return const LoginPage();
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
