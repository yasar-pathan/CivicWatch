import 'package:civic_watch/views/authentication/login_screen.dart';
import 'package:civic_watch/services/admin_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _isBackfilling = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text(
            'Admin Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'System Administrator account. Email/password changes are disabled in app.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF6366f1),
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: const Text('Administrator', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                user?.email ?? 'admin.civicwatch@gmail.com',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Email Notifications'),
            value: true,
            activeThumbColor: const Color(0xFF6366f1),
            onChanged: (val) {},
          ),
          SwitchListTile(
            title: const Text('Push Notifications'),
            value: true,
            activeThumbColor: const Color(0xFF6366f1),
            onChanged: (val) {},
          ),
          Card(
            color: const Color(0xFF1E293B),
            child: const ListTile(
              title: Text('Activity logging'),
              subtitle: Text('Always enabled for audit trail'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            color: const Color(0xFF1E293B),
            child: ListTile(
              leading: const Icon(Icons.sync, color: Color(0xFF6366f1)),
              title: const Text('Fix Existing City Names'),
              subtitle: const Text(
                'Run one-time migration to normalize city names (Nadiad/nadiad).',
              ),
              trailing: _isBackfilling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : ElevatedButton(
                      onPressed: () async {
                        setState(() => _isBackfilling = true);
                        try {
                          final result =
                              await AdminService().backfillCityNormalization();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Migration complete. Users: ${result['usersUpdated']}, Issues: ${result['issuesUpdated']}',
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Migration failed: $e')),
                          );
                        } finally {
                          if (mounted) setState(() => _isBackfilling = false);
                        }
                      },
                      child: const Text('Run'),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFef4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
