import 'package:civic_watch/services/state_authority_service.dart';
import 'package:civic_watch/views/authority/state/screens/create_city_authority_screen.dart';
import 'package:civic_watch/views/authority/state/screens/non_escalated_issues_screen.dart';
import 'package:civic_watch/views/authority/state/screens/pending_city_requests_screen.dart';
import 'package:civic_watch/views/authority/state/screens/state_activity_logs_screen.dart';
import 'package:civic_watch/views/authority/state/screens/city_wise_analytics_screen.dart';
import 'package:flutter/material.dart';

class StateHomeTab extends StatelessWidget {
  const StateHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: StateAuthorityService().getStateDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load dashboard: ${snapshot.error}'));
        }

        final data = snapshot.data ?? {};
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Text(
              'State Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _stat('City Authorities', data['totalCityAuthorities'] ?? 0, const Color(0xFF38BDF8)),
                _stat('Pending Requests', data['pendingCityRequests'] ?? 0, const Color(0xFFF59E0B)),
                _stat('Total Issues', data['totalIssues'] ?? 0, const Color(0xFF22C55E)),
                _stat('Escalated Issues', data['escalatedIssues'] ?? 0, const Color(0xFFEF4444)),
                _stat('Non-Escalated', data['nonEscalatedIssues'] ?? 0, const Color(0xFF6366F1)),
                _stat('Resolved This Month', data['resolvedThisMonth'] ?? 0, const Color(0xFF10B981)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _action(context, 'Create New City Authority', Icons.person_add_alt_1,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCityAuthorityScreen()))),
                _action(context, 'Pending City Requests', Icons.pending_actions,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingCityRequestsScreen()))),
                _action(context, 'View Non-Escalated Issues', Icons.list_alt,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NonEscalatedIssuesScreen()))),
                _action(context, 'City-wise Performance', Icons.bar_chart,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CityWiseAnalyticsScreen()))),
                _action(context, 'Activity Logs', Icons.history,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StateActivityLogsScreen()))),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _stat(String label, dynamic value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$value',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _action(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
    );
  }
}
