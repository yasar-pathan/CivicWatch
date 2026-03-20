import 'package:civic_watch/services/city_authority_service.dart';
import 'package:civic_watch/views/authority/city/tabs/city_all_issues_tab.dart';
import 'package:civic_watch/views/authority/city/tabs/city_analytics_tab.dart';
import 'package:civic_watch/views/authority/city/tabs/city_escalated_tab.dart';
import 'package:civic_watch/views/authority/city/tabs/city_home_tab.dart';
import 'package:civic_watch/views/authority/city/tabs/city_profile_tab.dart';
import 'package:civic_watch/theme/jellyfish_theme.dart';
import 'package:civic_watch/views/authentication/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CityDashboardScreen extends StatefulWidget {
  const CityDashboardScreen({super.key});

  @override
  State<CityDashboardScreen> createState() => _CityDashboardScreenState();
}

class _CityDashboardScreenState extends State<CityDashboardScreen> {
  int _index = 0;

  final _tabs = const [
    CityHomeTab(),
    CityAllIssuesTab(),
    CityEscalatedTab(),
    CityAnalyticsTab(),
    CityProfileTab(),
  ];

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: JellyfishTheme.darkTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('City Authority'),
          actions: [
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: JellyfishBackground(
          child: IndexedStack(index: _index, children: _tabs),
        ),
        bottomNavigationBar: StreamBuilder<Map<String, int>>(
          stream: CityAuthorityService().streamNavCounts(),
          builder: (context, snapshot) {
            final pending = snapshot.data?['pending'] ?? 0;
            final escalated = snapshot.data?['escalated'] ?? 0;

            return BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              type: BottomNavigationBarType.fixed,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: _badgeIcon(Icons.list_alt, pending),
                  label: 'All Issues',
                ),
                BottomNavigationBarItem(
                  icon: _badgeIcon(Icons.warning_amber, escalated),
                  label: 'Escalated',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.analytics),
                  label: 'Analytics',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _badgeIcon(IconData icon, int count) {
    if (count <= 0) return Icon(icon);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -8,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
