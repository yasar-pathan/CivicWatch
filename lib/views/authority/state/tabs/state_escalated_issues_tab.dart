import 'package:civic_watch/services/state_authority_service.dart';
import 'package:civic_watch/views/authority/state/screens/escalated_issue_detail_screen.dart';
import 'package:flutter/material.dart';

class StateEscalatedIssuesTab extends StatelessWidget {
  const StateEscalatedIssuesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: StateAuthorityService().getIssues(escalated: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load escalated issues: ${snapshot.error}'));
        }

        final issues = snapshot.data ?? [];
        if (issues.isEmpty) {
          return const Center(child: Text('No escalated issues in your state.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: issues.length,
          itemBuilder: (context, index) {
            final issue = issues[index];
            return Card(
              color: const Color(0xFF1E293B),
              child: ListTile(
                leading: const Icon(Icons.warning_amber, color: Color(0xFFEF4444)),
                title: Text(
                  (issue['title'] ?? 'Untitled').toString(),
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${issue['City'] ?? issue['city'] ?? 'N/A'} • ${issue['category'] ?? 'N/A'}\n${issue['status'] ?? 'N/A'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                isThreeLine: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EscalatedIssueDetailScreen(issue: issue),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
