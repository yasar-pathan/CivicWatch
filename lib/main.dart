import 'package:civic_watch/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:civic_watch/views/authentication/login_screen.dart';
import 'package:civic_watch/views/authentication/splash_screen.dart';
import 'package:civic_watch/views/citizen/dashboard_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CivicWatch',
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),
    );
  }
}
