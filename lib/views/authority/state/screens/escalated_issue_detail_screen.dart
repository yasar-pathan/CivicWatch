import 'package:civic_watch/services/state_authority_service.dart';
import 'package:flutter/material.dart';

class EscalatedIssueDetailScreen extends StatefulWidget {
  const EscalatedIssueDetailScreen({super.key, required this.issue});

  final Map<String, dynamic> issue;

  @override
  State<EscalatedIssueDetailScreen> createState() => _EscalatedIssueDetailScreenState();
}

class _EscalatedIssueDetailScreenState extends State<EscalatedIssueDetailScreen> {
  final _commentController = TextEditingController();
  bool _pushReminder = true;
  bool _markCritical = false;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    return Scaffold(
      appBar: AppBar(title: const Text('Escalated Issue Detail')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: const Color(0xFF1E293B),
            child: ListTile(
              title: Text(
                (issue['title'] ?? 'Untitled').toString(),
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${issue['City'] ?? issue['city'] ?? 'N/A'} • ${issue['category'] ?? 'N/A'}\n${issue['description'] ?? ''}',
                style: const TextStyle(color: Colors.white70),
              ),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Take Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Comment / Directive',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _pushReminder,
            onChanged: (v) => setState(() => _pushReminder = v ?? false),
            title: const Text('Push reminder to assigned City Authority'),
          ),
          CheckboxListTile(
            value: _markCritical,
            onChanged: (v) => setState(() => _markCritical = v ?? false),
            title: const Text('Flag as critical'),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _submitting
                ? null
                : () async {
                    final text = _commentController.text.trim();
                    if (text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please add a directive/comment.')),
                      );
                      return;
                    }
                    setState(() => _submitting = true);
                    try {
                      await StateAuthorityService().addEscalatedIssueComment(
                        issueId: (issue['id'] ?? '').toString(),
                        comment: text,
                        pushReminder: _pushReminder,
                        markCritical: _markCritical,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Action submitted successfully.')),
                      );
                      _commentController.clear();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: $e')),
                      );
                    } finally {
                      if (mounted) setState(() => _submitting = false);
                    }
                  },
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_submitting ? 'Submitting...' : 'Submit Action'),
          ),
        ],
      ),
    );
  }
}
