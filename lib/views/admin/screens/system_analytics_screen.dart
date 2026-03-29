import 'package:civic_watch/services/admin_service.dart';
import 'package:flutter/material.dart';
import 'package:civic_watch/widgets/charts/dashboard_charts.dart';

class SystemAnalyticsScreen extends StatelessWidget {
  const SystemAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Analytics')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: AdminService().fetchSystemAnalytics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Unable to load analytics: ${snapshot.error}'));
          }

          final data = snapshot.data ?? {};
          final userPoints = [
            ChartPoint('Citizens', _toDouble(data['citizens'])),
            ChartPoint('City Auth', _toDouble(data['cityAuthorities'])),
            ChartPoint('State Auth', _toDouble(data['stateAuthorities'])),
            ChartPoint('Admins', _toDouble(data['admins'])),
          ];

          final issuePoints = [
            ChartPoint('Resolved', _toDouble(data['resolvedIssues'])),
            ChartPoint('In Progress', _toDouble(data['inProgressIssues'])),
            ChartPoint('Pending', _toDouble(data['pendingIssues'])),
            ChartPoint('Escalated', _toDouble(data['escalatedIssues'])),
          ];

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _sectionTitle('Users'),
              DonutChartCard(title: 'User Role Distribution', points: userPoints),
              _metricCard('Total Users', data['totalUsers'] ?? 0, Icons.people),
              _metricCard('Citizens', data['citizens'] ?? 0, Icons.person),
              _metricCard('City Authorities', data['cityAuthorities'] ?? 0,
                  Icons.location_city),
              _metricCard('State Authorities', data['stateAuthorities'] ?? 0,
                  Icons.account_balance),
              _metricCard('Admin', data['admins'] ?? 0, Icons.admin_panel_settings),
              const SizedBox(height: 10),
              _sectionTitle('Issues'),
              ColumnChartCard(
                title: 'Issue Status Overview',
                points: issuePoints,
                yAxisTitle: 'Issues',
              ),
              _metricCard('Total Issues', data['totalIssues'] ?? 0,
                  Icons.report_problem),
              _metricCard('Resolved Issues', data['resolvedIssues'] ?? 0,
                  Icons.check_circle, color: const Color(0xFF4CAF50)),
              _metricCard('In Progress', data['inProgressIssues'] ?? 0,
                  Icons.work_history, color: const Color(0xFF03A9F4)),
              _metricCard('Pending', data['pendingIssues'] ?? 0, Icons.pending,
                  color: const Color(0xFFFF9800)),
              _metricCard('Escalated', data['escalatedIssues'] ?? 0,
                  Icons.trending_up, color: const Color(0xFFF44336)),
            ],
          );
        },
      ),
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _metricCard(String label, int value, IconData icon,
      {Color color = const Color(0xFF1565C0)}) {
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        trailing: Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
