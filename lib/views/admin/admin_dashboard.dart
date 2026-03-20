import 'package:civic_watch/views/admin/tabs/dashboard_tab.dart';
import 'package:civic_watch/views/admin/tabs/pending_requests_tab.dart';
import 'package:civic_watch/views/admin/tabs/settings_tab.dart';
import 'package:civic_watch/views/admin/tabs/state_authorities_tab.dart';
import 'package:civic_watch/theme/jellyfish_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:civic_watch/views/authentication/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _initializing = true;

  final List<Widget> _screens = [
    const DashboardTab(),
    const PendingRequestsTab(),
    const StateAuthoritiesTab(),
    const SettingsTab(),
  ];

  @override
  void initState() {
    super.initState();
    _ensureAdminDocument();
  }

  Future<void> _ensureAdminDocument() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email == 'admin.civicwatch@gmail.com') {
      try {
        // Try reading first
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!doc.exists || doc.data()?['role'] != 'admin') {
          // If missing or wrong role, force update/create
          debugPrint("Admin Doc Missing - Creating...");
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'role': 'admin',
            'status': 'approved',
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint("Admin Bootstrapping Error (Ignore if permission denied): $e");
      }
    }
    if (mounted) setState(() => _initializing = false);
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: JellyfishTheme.darkTheme(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: JellyfishBackground(
          child: _initializing
              ? const Center(child: CircularProgressIndicator())
              : IndexedStack(index: _selectedIndex, children: _screens),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
            BottomNavigationBarItem(icon: Icon(Icons.person_add_alt_1), label: 'Create'),
            BottomNavigationBarItem(icon: Icon(Icons.supervised_user_circle), label: 'State Auth'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
          ],
        ),
      ),
    );
  }
}

