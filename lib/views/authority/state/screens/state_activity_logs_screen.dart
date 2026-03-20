import 'package:civic_watch/services/state_authority_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StateActivityLogsScreen extends StatefulWidget {
  const StateActivityLogsScreen({super.key});

  @override
  State<StateActivityLogsScreen> createState() => _StateActivityLogsScreenState();
}

class _StateActivityLogsScreenState extends State<StateActivityLogsScreen> {
  String _actionFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('State Activity Logs')),
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
                DropdownMenuItem(value: 'created_ca', child: Text('Created CA')),
                DropdownMenuItem(value: 'approved_ca', child: Text('Approved CA')),
                DropdownMenuItem(value: 'rejected_ca', child: Text('Rejected CA')),
                DropdownMenuItem(value: 'edited_ca', child: Text('Edited CA')),
                DropdownMenuItem(value: 'deactivated_ca', child: Text('Deactivated CA')),
                DropdownMenuItem(value: 'activated_ca', child: Text('Activated CA')),
                DropdownMenuItem(value: 'deleted_ca', child: Text('Deleted CA')),
                DropdownMenuItem(value: 'commented_escalated_issue', child: Text('Escalated Issue Comment')),
              ],
              onChanged: (v) => setState(() => _actionFilter = v ?? 'all'),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: StateAuthorityService().getStateActivityLogs(limit: 200),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Failed: ${snapshot.error}'));
                }

                final logs = (snapshot.data ?? []).where((log) {
                  if (_actionFilter == 'all') return true;
                  return (log['action'] ?? '').toString() == _actionFilter;
                }).toList();

                if (logs.isEmpty) {
                  return const Center(child: Text('No logs found.'));
                }

                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final ts = log['timestamp'] as Timestamp?;
                    return Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.history, color: Color(0xFF03A9F4)),
                        title: Text(
                          (log['action'] ?? 'unknown').toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Target: ${(log['targetUserName'] ?? log['targetUserId'] ?? 'N/A')}\n'
                          'When: ${ts?.toDate() ?? 'N/A'}',
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
}
