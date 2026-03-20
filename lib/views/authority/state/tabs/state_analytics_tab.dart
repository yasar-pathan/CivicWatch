import 'package:civic_watch/services/state_authority_service.dart';
import 'package:civic_watch/views/authority/state/screens/city_wise_analytics_screen.dart';
import 'package:flutter/material.dart';

class StateAnalyticsTab extends StatelessWidget {
  const StateAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: StateAuthorityService().getStateAnalytics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed analytics: ${snapshot.error}'));
        }

        final d = snapshot.data ?? {};
        final byCity = (d['byCity'] as Map<String, dynamic>? ?? {});

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Text('State Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _tile('Total Issues', d['totalIssues'] ?? 0),
            _tile('Reported', d['reported'] ?? 0),
            _tile('Recognized', d['recognized'] ?? 0),
            _tile('In Work', d['inWork'] ?? 0),
            _tile('Done', d['done'] ?? 0),
            _tile('Escalated', d['escalated'] ?? 0),
            const SizedBox(height: 12),
            const Text('City-wise Performance', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...byCity.entries.map((e) {
              final val = e.value as Map<String, dynamic>;
              return Card(
                color: const Color(0xFF1E293B),
                child: ListTile(
                  title: Text(e.key, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    'Total: ${val['total'] ?? 0} | Resolved: ${val['resolved'] ?? 0} | Escalated: ${val['escalated'] ?? 0}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CityWiseAnalyticsScreen()),
              ),
              icon: const Icon(Icons.bar_chart),
              label: const Text('Open Detailed City-wise Analytics'),
            ),
          ],
        );
      },
    );
  }

  Widget _tile(String label, dynamic value) {
    return Card(
      color: const Color(0xFF1E293B),
      child: ListTile(
        title: Text(label),
        trailing: Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}
