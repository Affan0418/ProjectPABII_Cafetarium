import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:cafetarium/firebase_options.dart';
import 'package:cafetarium/screens/splash_screen.dart';
import 'package:cafetarium/screens/role_selection_screen.dart';
import 'package:cafetarium/screens/sign_in_screen.dart';
import 'package:cafetarium/screens/sign_up_screen.dart';
import 'package:cafetarium/screens/search_screen.dart';
import 'package:cafetarium/screens/favorite_screen.dart';
import 'package:cafetarium/screens/map_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> setupNotification() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission();

  await FirebaseMessaging.instance.subscribeToTopic('cafes');

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'cafes_channel',
    'Cafe Notifications',
    description: 'Notification for Cafetarium updates',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;

    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'cafes_channel',
            'Cafe Notifications',
            channelDescription: 'Notification for Cafetarium updates',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await setupNotification();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      initialRoute: '/splash',

      routes: {
        '/splash': (context) => const SplashScreen(),
        '/signin': (context) => const SignInScreen(role: 'Customer'),
        '/role': (context) => const RoleSelectionScreen(),
        '/signup': (context) => const SignUpScreen(role: 'Customer'),
        '/search': (context) => const SearchScreen(),
        '/favorite': (context) => const FavoriteScreen(),
        '/map': (context) => const MapScreen(),
      },
    );
  }
}