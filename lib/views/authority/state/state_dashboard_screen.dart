import 'package:civic_watch/views/authority/state/tabs/state_analytics_tab.dart';
import 'package:civic_watch/views/authority/state/tabs/state_city_authorities_tab.dart';
import 'package:civic_watch/views/authority/state/tabs/state_escalated_issues_tab.dart';
import 'package:civic_watch/views/authority/state/tabs/state_home_tab.dart';
import 'package:civic_watch/views/authority/state/tabs/state_profile_tab.dart';
import 'package:civic_watch/theme/jellyfish_theme.dart';
import 'package:civic_watch/views/authentication/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StateDashboardScreen extends StatefulWidget {
  const StateDashboardScreen({super.key});

  @override
  State<StateDashboardScreen> createState() => _StateDashboardScreenState();
}

class _StateDashboardScreenState extends State<StateDashboardScreen> {
  int _index = 0;

  final _tabs = const [
    StateHomeTab(),
    StateCityAuthoritiesTab(),
    StateEscalatedIssuesTab(),
    StateAnalyticsTab(),
    StateProfileTab(),
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
          title: const Text('State Authority'),
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
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'City Auth'),
            BottomNavigationBarItem(icon: Icon(Icons.warning_amber), label: 'Escalated'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
