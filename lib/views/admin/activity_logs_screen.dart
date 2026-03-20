import 'package:civic_watch/services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  String _actionFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Logs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              initialValue: _actionFilter,
              decoration: const InputDecoration(
                labelText: 'Action Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'created_sa', child: Text('Created SA')),
                DropdownMenuItem(value: 'edited_sa', child: Text('Edited SA')),
                DropdownMenuItem(value: 'reset_password', child: Text('Reset Password')),
                DropdownMenuItem(value: 'deactivated', child: Text('Deactivated')),
                DropdownMenuItem(value: 'activated', child: Text('Activated')),
                DropdownMenuItem(value: 'deleted', child: Text('Deleted')),
              ],
              onChanged: (value) => setState(() => _actionFilter = value ?? 'all'),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: AdminService().getActivityLogs(limit: 200),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final logs = (snapshot.data ?? []).where((entry) {
                  if (_actionFilter == 'all') return true;
                  return (entry['action'] ?? '').toString() == _actionFilter;
                }).toList();

                if (logs.isEmpty) {
                  return const Center(child: Text('No activity logs found.'));
                }

                return ListView.separated(
                  itemCount: logs.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Colors.white12),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final action = (log['action'] ?? 'unknown').toString();
                    final target = (log['targetUserName'] ?? 'N/A').toString();
                    final state = (log['targetUserState'] ?? '').toString();
                    final timestamp = log['timestamp'] is Timestamp
                        ? (log['timestamp'] as Timestamp).toDate()
                        : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: const Color(0xFF1E293B),
                      child: ListTile(
                        leading: const Icon(Icons.history, color: Color(0xFF03A9F4)),
                        title: Text(
                          _humanizeAction(action),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'User: $target${state.isNotEmpty ? ' ($state)' : ''}\n'
                          'By: ${(log['adminName'] ?? 'Admin')}\n'
                          '${timestamp?.toString() ?? 'No timestamp'}',
                          style: const TextStyle(color: Colors.white70),
                        ),
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

  String _humanizeAction(String action) {
    switch (action) {
      case 'created_sa':
        return 'Created State Authority';
      case 'edited_sa':
        return 'Edited State Authority';
      case 'reset_password':
        return 'Reset Password';
      case 'deactivated':
        return 'Deactivated Account';
      case 'activated':
        return 'Activated Account';
      case 'deleted':
        return 'Deleted Account';
      default:
        return action;
    }
  }
}
