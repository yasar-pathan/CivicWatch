import 'package:civic_watch/services/city_authority_service.dart';
import 'package:flutter/material.dart';

class PerformanceComparisonScreen extends StatelessWidget {
  const PerformanceComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text('Performance Comparison'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Future.wait([
          CityAuthorityService().getCityAnalytics(range: 'Last 7 days'),
          CityAuthorityService().getCityAnalytics(range: 'Last 30 days'),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed: ${snapshot.error}'));
          }

          final now = snapshot.data?[0] ?? {};
          final last = snapshot.data?[1] ?? {};

          final nowScore = (now['performanceScore'] ?? 0) as int;
          final lastScore = (last['performanceScore'] ?? 0) as int;
          final diff = nowScore - lastScore;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                color: const Color(0xFF1E293B),
                child: ListTile(
                  title: const Text('Current (Last 7 days)'),
                  trailing: Text('$nowScore', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
              Card(
                color: const Color(0xFF1E293B),
                child: ListTile(
                  title: const Text('Baseline (Last 30 days)'),
                  trailing: Text('$lastScore', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
              Card(
                color: const Color(0xFF1E293B),
                child: ListTile(
                  title: const Text('Trend'),
                  subtitle: Text(diff >= 0 ? 'Better than baseline' : 'Worse than baseline'),
                  trailing: Text(
                    diff >= 0 ? '+$diff' : '$diff',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: diff >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Goal: Resolve 90% issues in <10 days'),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: ((now['resolutionRate'] ?? 0.0) / 100.0).clamp(0.0, 1.0),
                minHeight: 12,
                borderRadius: BorderRadius.circular(10),
                backgroundColor: const Color(0xFF334155),
                color: const Color(0xFF22C55E),
              ),
              const SizedBox(height: 8),
              Text('Current resolution rate: ${(now['resolutionRate'] ?? 0.0).toStringAsFixed(1)}%'),
            ],
          );
        },
      ),
    );
  }
}
