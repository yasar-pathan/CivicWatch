import 'package:civic_watch/services/city_authority_service.dart';
import 'package:civic_watch/views/authority/city/screens/city_issues_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:civic_watch/widgets/charts/dashboard_charts.dart';

class CityHomeTab extends StatelessWidget {
  const CityHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: CityAuthorityService().getDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load dashboard: ${snapshot.error}'));
        }

        final data = snapshot.data ?? {};
        final categories = (data['categories'] as Map<String, dynamic>? ?? {});
        final statusPoints = [
          ChartPoint('Reported', _toDouble(data['reported'])),
          ChartPoint('Recognized', _toDouble(data['recognized'])),
          ChartPoint('In Work', _toDouble(data['inWork'])),
          ChartPoint('Done', _toDouble(data['done'])),
          ChartPoint('Escalated', _toDouble(data['escalated'])),
        ];
        final categoryPoints = categories.entries
            .map((e) => ChartPoint(e.key, _toDouble(e.value)))
            .toList();

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Text('City Dashboard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _stat('Total Issues', data['totalIssues'] ?? 0, const Color(0xFF38BDF8)),
                _stat('Reported', data['reported'] ?? 0, const Color(0xFFF59E0B)),
                _stat('Recognized', data['recognized'] ?? 0, const Color(0xFFFB923C)),
                _stat('In Work', data['inWork'] ?? 0, const Color(0xFF0EA5E9)),
                _stat('Done', data['done'] ?? 0, const Color(0xFF22C55E)),
                _stat('Escalated', data['escalated'] ?? 0, const Color(0xFFEF4444)),
                _stat('Avg Resolution (days)',
                    (data['avgResolutionDays'] ?? 0.0).toStringAsFixed(1),
                    const Color(0xFFA78BFA)),
                _stat('Resolved This Month', data['resolvedThisMonth'] ?? 0,
                    const Color(0xFF10B981)),
              ],
            ),
            const SizedBox(height: 12),
            DonutChartCard(title: 'Status Breakdown', points: statusPoints),
            ColumnChartCard(
              title: 'Category Volume',
              points: categoryPoints,
              yAxisTitle: 'Issues',
            ),
            const SizedBox(height: 14),
            const Text('Urgent Alerts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: CityAuthorityService().getUrgentAlerts(),
              builder: (context, snap) {
                final alerts = snap.data ?? [];
                if (alerts.isEmpty) {
                  return const Card(
                    color: Color(0xFF1E293B),
                    child: ListTile(title: Text('No urgent alerts right now.')),
                  );
                }
                return Column(
                  children: alerts.take(5).map((a) {
                    return Card(
                      color: const Color(0xFF7F1D1D),
                      child: ListTile(
                        title: Text((a['title'] ?? 'Untitled').toString()),
                        subtitle: Text(
                          '${a['category'] ?? 'N/A'} • ${a['daysPending'] ?? 0} days pending • escalates in ${a['countdown'] ?? 0} days',
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CityIssuesListScreen(
                                title: 'Pending Issues',
                                initialStatus: 'Recognized',
                              ),
                            ),
                          ),
                          child: const Text('Take Action'),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            const Text('Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _action(
                  context,
                  '📋 View Pending Issues',
                  Icons.pending_actions,
                  const CityIssuesListScreen(title: 'Pending Issues', initialStatus: 'Reported'),
                ),
                _action(
                  context,
                  '🔧 View In Progress Issues',
                  Icons.engineering,
                  const CityIssuesListScreen(title: 'In Progress', initialStatus: 'In Work'),
                ),
                _action(
                  context,
                  '🚨 View Escalated Issues',
                  Icons.warning_amber,
                  const CityIssuesListScreen(title: 'Escalated Issues', onlyEscalated: true),
                ),
                _action(
                  context,
                  '✅ View Completed Issues',
                  Icons.check_circle,
                  const CityIssuesListScreen(title: 'Completed Issues', initialStatus: 'Done'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Category-wise Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.entries.map((e) {
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CityIssuesListScreen(
                        title: '${e.key} Issues',
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text('${e.key}: ${e.value}'),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const Text('Recent Issues Timeline',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: CityAuthorityService().getRecentIssues(limit: 10),
              builder: (context, snap) {
                final recent = snap.data ?? [];
                if (recent.isEmpty) {
                  return const Card(
                    color: Color(0xFF1E293B),
                    child: ListTile(title: Text('No recent issues found.')),
                  );
                }
                return Column(
                  children: recent.map((i) {
                    return Card(
                      color: const Color(0xFF1E293B),
                      child: ListTile(
                        leading: (i['photoUrl'] ?? '').toString().isEmpty
                            ? const CircleAvatar(child: Icon(Icons.report_problem))
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  i['photoUrl'].toString(),
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.cover,
                                ),
                              ),
                        title: Text((i['title'] ?? '').toString()),
                        subtitle: Text(
                          '${i['category'] ?? 'N/A'} • ${i['status'] ?? 'N/A'}',
                        ),
                        trailing: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CityIssuesListScreen(
                                title: 'All Issues',
                              ),
                            ),
                          ),
                          child: const Text('Update'),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  Widget _action(BuildContext context, String label, IconData icon, Widget target) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => target)),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
    );
  }
}
