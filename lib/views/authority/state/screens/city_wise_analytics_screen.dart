import 'package:civic_watch/services/state_authority_service.dart';
import 'package:flutter/material.dart';
import 'package:civic_watch/widgets/charts/dashboard_charts.dart';

class CityWiseAnalyticsScreen extends StatefulWidget {
  const CityWiseAnalyticsScreen({super.key});

  @override
  State<CityWiseAnalyticsScreen> createState() => _CityWiseAnalyticsScreenState();
}

class _CityWiseAnalyticsScreenState extends State<CityWiseAnalyticsScreen> {
  String _selectedCity = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('City-wise Detailed Analytics')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: StateAuthorityService().getStateAnalytics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed analytics: ${snapshot.error}'));
          }

          final analytics = snapshot.data ?? {};
          final byCity = (analytics['byCity'] as Map<String, dynamic>? ?? {});
          final cities = ['All', ...byCity.keys.toList()..sort()];
          if (!cities.contains(_selectedCity)) _selectedCity = 'All';

          final rows = _selectedCity == 'All'
              ? byCity.entries.toList()
              : byCity.entries.where((e) => e.key == _selectedCity).toList();

          final points = rows
              .map(
                (entry) => ChartPoint(
                  entry.key,
                  _toDouble((entry.value as Map<String, dynamic>)['total']),
                ),
              )
              .toList();

          if (rows.isEmpty) {
            return const Center(child: Text('No city analytics available.'));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedCity,
                decoration: const InputDecoration(
                  labelText: 'Select City',
                  border: OutlineInputBorder(),
                ),
                items: cities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCity = v ?? 'All'),
              ),
              const SizedBox(height: 12),
              ColumnChartCard(
                title: 'City Total Issues',
                points: points,
                yAxisTitle: 'Issues',
              ),
              ...rows.map((entry) {
                final city = entry.key;
                final v = entry.value as Map<String, dynamic>;
                final total = (v['total'] ?? 0) as int;
                final resolved = (v['resolved'] ?? 0) as int;
                final pending = (v['pending'] ?? 0) as int;
                final escalated = (v['escalated'] ?? 0) as int;
                final rate = total == 0 ? 0.0 : (resolved * 100 / total);

                return Card(
                  color: const Color(0xFF1E293B),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(city,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 8),
                        Text('Total Issues: $total'),
                        Text('Resolved: $resolved'),
                        Text('Pending: $pending'),
                        Text('Escalated: $escalated'),
                        const SizedBox(height: 6),
                        Text('Resolution Rate: ${rate.toStringAsFixed(1)}%'),
                      ],
                    ),
                  ),
                );
              }),
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
}
