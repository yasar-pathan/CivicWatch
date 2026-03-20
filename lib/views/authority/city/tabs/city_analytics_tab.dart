import 'package:civic_watch/services/city_authority_service.dart';
import 'package:civic_watch/views/authority/city/screens/performance_comparison_screen.dart';
import 'package:flutter/material.dart';

class CityAnalyticsTab extends StatefulWidget {
  const CityAnalyticsTab({super.key});

  @override
  State<CityAnalyticsTab> createState() => _CityAnalyticsTabState();
}

class _CityAnalyticsTabState extends State<CityAnalyticsTab> {
  String _range = 'Last 30 days';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: CityAuthorityService().getCityAnalytics(range: _range),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed analytics: ${snapshot.error}'));
        }

        final d = snapshot.data ?? {};
        final status = (d['statusCounts'] as Map<String, dynamic>? ?? {});
        final category = (d['categoryBreakdown'] as Map<String, dynamic>? ?? {});
        final performance = (d['performanceScore'] ?? 0) as int;

        Color perfColor = const Color(0xFF22C55E);
        if (performance < 80) perfColor = const Color(0xFFF59E0B);
        if (performance < 50) perfColor = const Color(0xFFEF4444);

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Text('City Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _range,
              decoration: const InputDecoration(
                labelText: 'Date Range',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Last 7 days', child: Text('Last 7 days')),
                DropdownMenuItem(value: 'Last 30 days', child: Text('Last 30 days')),
              ],
              onChanged: (v) => setState(() => _range = v ?? 'Last 30 days'),
            ),
            const SizedBox(height: 10),
            _tile('Total', d['total'] ?? 0),
            _tile('Resolution Rate', '${(d['resolutionRate'] ?? 0.0).toStringAsFixed(1)}%'),
            _tile('Escalation Rate', '${(d['escalationRate'] ?? 0.0).toStringAsFixed(1)}%'),
            Card(
              color: const Color(0xFF1E293B),
              child: ListTile(
                title: const Text('Performance Score'),
                trailing: Text(
                  '$performance',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: perfColor),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Status Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
            ...status.entries.map((e) => _tile(e.key, e.value)),
            const SizedBox(height: 8),
            const Text('Category Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
            ...category.entries.map((e) {
              final v = e.value as Map<String, dynamic>;
              return Card(
                color: const Color(0xFF1E293B),
                child: ListTile(
                  title: Text(e.key),
                  subtitle: Text(
                    'Total: ${v['total'] ?? 0} | Resolved: ${v['resolved'] ?? 0} | Pending: ${v['pending'] ?? 0}',
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerformanceComparisonScreen()),
              ),
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Performance Comparison'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Export (PDF/CSV) can be enabled via Cloud Function or local generator.'),
                  ),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Export Report'),
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
