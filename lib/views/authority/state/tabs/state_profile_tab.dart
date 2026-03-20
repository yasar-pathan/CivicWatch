import 'package:civic_watch/services/state_authority_service.dart';
import 'package:civic_watch/views/authority/state/screens/change_password_screen.dart';
import 'package:civic_watch/views/authority/state/screens/state_activity_logs_screen.dart';
import 'package:flutter/material.dart';

class StateProfileTab extends StatelessWidget {
  const StateProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: StateAuthorityService().getCurrentStateAuthorityProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed profile load: ${snapshot.error}'));
        }

        final d = snapshot.data ?? {};
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              color: const Color(0xFF1E293B),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF6366F1),
                  child: Icon(Icons.account_balance, color: Colors.white),
                ),
                title: Text((d['name'] ?? 'State Authority').toString(), style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  '${d['email'] ?? ''}\nState: ${d['state'] ?? 'N/A'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                isThreeLine: true,
              ),
            ),
            Card(
              color: const Color(0xFF1E293B),
              child: ListTile(
                title: const Text('Government Employee ID'),
                subtitle: Text((d['governmentId'] ?? 'N/A').toString()),
              ),
            ),
            Card(
              color: const Color(0xFF1E293B),
              child: ListTile(
                title: const Text('Department'),
                subtitle: Text((d['department'] ?? 'N/A').toString()),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              ),
              icon: const Icon(Icons.lock_reset),
              label: const Text('Change Password'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StateActivityLogsScreen()),
              ),
              icon: const Icon(Icons.history),
              label: const Text('Activity Logs'),
            ),
          ],
        );
      },
    );
  }
}
