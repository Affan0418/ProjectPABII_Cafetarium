import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/main_screen.dart';
import 'screens/search_screen.dart';
import 'screens/favorite_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      },
    );
  }
}
