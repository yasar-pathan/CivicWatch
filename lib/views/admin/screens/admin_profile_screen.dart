import 'package:civic_watch/views/authentication/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: const Color(0xFF1E293B),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1565C0),
                child: Icon(Icons.admin_panel_settings, color: Colors.white),
              ),
              title: const Text('Admin', style: TextStyle(color: Colors.white)),
              subtitle: Text(user?.email ?? 'admin.civicwatch@gmail.com',
                  style: const TextStyle(color: Colors.white70)),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Notification Preferences',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Email notifications'),
          ),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Push notifications'),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  title: const Text('Logout?'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF44336)),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
