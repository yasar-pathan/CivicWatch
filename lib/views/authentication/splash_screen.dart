import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civic_watch/views/admin/admin_dashboard.dart';
import 'package:civic_watch/views/authority/city/city_dashboard_screen.dart';
import 'package:civic_watch/views/authority/state/state_dashboard_screen.dart';
import 'package:civic_watch/views/citizen/dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _normalizeRole(dynamic role) {
    return role
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
  }

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 12), () async {
      if (!mounted) return;
      final nextScreen = await _resolveNextScreen();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    });
  }

  Future<Widget> _resolveNextScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginScreen();

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        return const LoginScreen();
      }

      final data = userDoc.data() ?? <String, dynamic>{};
      final role = _normalizeRole(data['role'] ?? 'citizen');
      final status = (data['status'] ?? 'approved').toString();
      final isActive = data['isActive'] != false;

      if (!isActive || status == 'pending_approval' || status == 'rejected') {
        await FirebaseAuth.instance.signOut();
        return const LoginScreen();
      }

      if (role == 'admin') return const AdminDashboardScreen();
      if (role == 'state_authority') return const StateDashboardScreen();
      if (role == 'city_authority') return const CityDashboardScreen();
      return const DashboardScreen();
    } catch (_) {
      await FirebaseAuth.instance.signOut();
      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = (screenWidth * 0.30).clamp(110.0, 150.0);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF050506),
                  Color(0xFF101113),
                  Color(0xFF1C1812),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -140,
            right: -90,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -160,
            left: -110,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8D6E2F).withValues(alpha: 0.10),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(2.2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF2DE98), Color(0xFFB38728)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Image.asset(
                      'assets/images/appicon.png',
                      width: logoSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                const Text(
                  'Civic Watch',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF6E3AD),
                    letterSpacing: 1.7,
                    shadows: [
                      Shadow(
                        color: Color(0xAA000000),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'EMPOWERING CITIZENS, ENABLING CHANGE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFE3C672),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE8C86B)),
                  strokeWidth: 3.2,
                ),
                const SizedBox(height: 22),
                const Text(
                  'Preparing your experience...',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFFCFD2D6),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
