
import 'package:civic_watch/core/theme/app_theme.dart';
import 'package:civic_watch/views/authentication/login_screen.dart';
import 'package:civic_watch/views/authentication/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:civic_watch/views/citizen/dashboard_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:civic_watch/views/authentication/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CivicWatch',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }

  Widget _getHome() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return const DashboardScreen();
    } else {
      return const LoginScreen();
    }
  }
}
