import 'package:civic_watch/services/city_authority_service.dart';
import 'package:flutter/material.dart';

class CityActivityLogsScreen extends StatefulWidget {
  const CityActivityLogsScreen({super.key});

  @override
  State<CityActivityLogsScreen> createState() => _CityActivityLogsScreenState();
}

class _CityActivityLogsScreenState extends State<CityActivityLogsScreen> {
  String _type = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text('Activity Logs'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Action Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'status_updated', child: Text('Status Updated')),
                DropdownMenuItem(value: 'comment_added', child: Text('Comment Added')),
                DropdownMenuItem(value: 'password_changed', child: Text('Password Changed')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'All'),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: CityAuthorityService().streamActivityLogs(type: _type),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Failed: ${snapshot.error}'));
                }

                final logs = snapshot.data ?? [];
                if (logs.isEmpty) {
                  return const Center(child: Text('No logs found for selected filter.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Card(
                      color: const Color(0xFF1E293B),
                      child: ListTile(
                        title: Text((log['action'] ?? 'action').toString()),
                        subtitle: Text('Issue: ${log['issueId'] ?? '-'}\n${log['details'] ?? {}}'),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
