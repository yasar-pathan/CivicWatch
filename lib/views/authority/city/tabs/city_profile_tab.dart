import 'package:civic_watch/services/city_authority_service.dart';
import 'package:civic_watch/views/authority/city/screens/city_activity_logs_screen.dart';
import 'package:civic_watch/views/authority/city/screens/city_change_password_screen.dart';
import 'package:civic_watch/views/authority/city/screens/city_notifications_screen.dart';
import 'package:civic_watch/views/authority/city/screens/invalid_issues_screen.dart';
import 'package:flutter/material.dart';

class CityProfileTab extends StatefulWidget {
  const CityProfileTab({super.key});

  @override
  State<CityProfileTab> createState() => _CityProfileTabState();
}

class _CityProfileTabState extends State<CityProfileTab> {
  bool _push = true;
  bool _email = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: CityAuthorityService().getCurrentCityAuthorityProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed profile load: ${snapshot.error}'));
        }

        final profile = snapshot.data!;
        final statsFuture = CityAuthorityService().getDashboardStats();

        return FutureBuilder<Map<String, dynamic>>(
          future: statsFuture,
          builder: (context, statsSnap) {
            final stats = statsSnap.data ?? {};
            final total = (stats['totalIssues'] ?? 0) as int;
            final resolved = (stats['done'] ?? 0) as int;
            final escalations = (stats['escalated'] ?? 0) as int;
            final ratio = total == 0 ? 0.0 : (resolved / total * 100);

            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  color: const Color(0xFF1E293B),
                  child: ListTile(
                    leading: const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFF6366F1),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(profile.name ?? 'City Authority'),
                    subtitle: Text('${profile.email}\n${profile.city ?? 'N/A'}, ${profile.state ?? 'N/A'}'),
                    isThreeLine: true,
                  ),
                ),
                _tile('Phone', profile.phone ?? 'N/A'),
                _tile('Government Employee ID', profile.governmentId ?? 'N/A'),
                _tile('Department', profile.department ?? 'N/A'),
                _tile('Office Address', profile.officeAddress ?? 'N/A'),
                const SizedBox(height: 8),
                const Text('Performance Stats', style: TextStyle(fontWeight: FontWeight.bold)),
                _tile('Total Issues Managed', total),
                _tile('Issues Resolved', '$resolved (${ratio.toStringAsFixed(1)}%)'),
                _tile('Escalations', escalations),
                _tile('Average Resolution Time',
                    '${(stats['avgResolutionDays'] ?? 0.0).toStringAsFixed(1)} days'),
                const SizedBox(height: 8),
                const Text('Notification Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
                SwitchListTile(
                  value: _push,
                  onChanged: (v) async {
                    setState(() => _push = v);
                    await CityAuthorityService().updateNotificationPreferences(
                      prefs: {'push': _push, 'email': _email},
                    );
                  },
                  title: const Text('Push Notifications'),
                ),
                SwitchListTile(
                  value: _email,
                  onChanged: (v) async {
                    setState(() => _email = v);
                    await CityAuthorityService().updateNotificationPreferences(
                      prefs: {'push': _push, 'email': _email},
                    );
                  },
                  title: const Text('Email Notifications'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CityChangePasswordScreen()),
                  ),
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Change Password'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CityNotificationsScreen()),
                  ),
                  icon: const Icon(Icons.notifications),
                  label: const Text('Notifications'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CityActivityLogsScreen()),
                  ),
                  icon: const Icon(Icons.history),
                  label: const Text('Activity Logs'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InvalidIssuesScreen()),
                  ),
                  icon: const Icon(Icons.block),
                  label: const Text('Invalid/Spam Issues'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _tile(String label, dynamic value) {
    return Card(
      color: const Color(0xFF1E293B),
      child: ListTile(
        title: Text(label),
        subtitle: Text('$value'),
      ),
    );
  }
}
