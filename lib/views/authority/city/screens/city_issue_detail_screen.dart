import 'dart:io';

import 'package:civic_watch/services/city_authority_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CityIssueDetailScreen extends StatefulWidget {
  const CityIssueDetailScreen({super.key, required this.issue});

  final Map<String, dynamic> issue;

  @override
  State<CityIssueDetailScreen> createState() => _CityIssueDetailScreenState();
}

class _CityIssueDetailScreenState extends State<CityIssueDetailScreen> {
  final _service = CityAuthorityService();
  final _commentCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _showStatusDialog(Map<String, dynamic> issue) async {
    final current = (issue['status'] ?? 'Reported').toString();
    String next = current == 'Reported'
        ? 'Recognized'
        : current == 'Recognized'
            ? 'In Work'
            : current == 'In Work'
                ? 'Done'
                : current;

    final notesCtrl = TextEditingController();
    final invalidCtrl = TextEditingController();
    File? afterFile;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final options = current == 'Reported'
                ? ['Recognized', 'Invalid']
                : current == 'Recognized'
                    ? ['In Work']
                    : current == 'In Work'
                        ? ['Done']
                        : <String>[];

            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text('Update Issue Status'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current: $current'),
                    const SizedBox(height: 8),
                    if (options.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: options.contains(next) ? next : options.first,
                        items: options
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setLocal(() => next = v ?? options.first),
                        decoration: const InputDecoration(
                          labelText: 'Next Status',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    if (options.isEmpty)
                      const Text('No status changes allowed for this issue.'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (next == 'Invalid') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: invalidCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Invalid reason',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    if (next == 'Done') ...[
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                            maxWidth: 1920,
                            maxHeight: 1080,
                          );
                          if (picked != null) {
                            setLocal(() => afterFile = File(picked.path));
                          }
                        },
                        icon: const Icon(Icons.photo_camera_back),
                        label: const Text('Upload After Photo (Required)'),
                      ),
                      if (afterFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Selected: ${afterFile!.path.split('\\').last}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: options.isEmpty
                      ? null
                      : () async {
                          if (next == 'Done' && afterFile == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('After photo is required for Done.')),
                            );
                            return;
                          }
                          if (next == 'Invalid' && invalidCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please provide invalid reason.')),
                            );
                            return;
                          }

                          Navigator.pop(context, {
                            'next': next,
                            'notes': notesCtrl.text.trim(),
                            'invalidReason': invalidCtrl.text.trim(),
                            'afterFile': afterFile,
                          });
                        },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) async {
      if (result is! Map<String, dynamic>) return;

      setState(() => _saving = true);
      try {
        String? afterUrl;
        final file = result['afterFile'] as File?;
        if (file != null) {
          afterUrl = await _service.uploadAfterPhoto(
            issueId: (issue['id'] ?? '').toString(),
            file: file,
          );
        }

        await _service.updateIssueStatus(
          issueId: (issue['id'] ?? '').toString(),
          newStatus: (result['next'] ?? '').toString(),
          notes: (result['notes'] ?? '').toString(),
          invalidReason: (result['invalidReason'] ?? '').toString(),
          afterPhotoUrl: afterUrl,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue status updated successfully.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    final status = (issue['status'] ?? 'Reported').toString();
    final history = (issue['statusHistory'] as List<dynamic>? ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text('Issue Detail'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if ((issue['photoUrl'] ?? '').toString().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    issue['photoUrl'].toString(),
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 10),
              Card(
                color: const Color(0xFF1E293B),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (issue['title'] ?? 'Untitled').toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (issue['description'] ?? '').toString(),
                        style: const TextStyle(color: Color(0xFFCBD5E1)),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _pill('Status: $status', _statusColor(status)),
                          _pill('Category: ${(issue['category'] ?? 'N/A')}', const Color(0xFF334155)),
                          _pill('Priority: ${(issue['priority'] ?? 'Medium')}', const Color(0xFF0EA5E9)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Issue ID: ${(issue['id'] ?? '').toString()}',
                        style: const TextStyle(color: Color(0xFF94A3B8)),
                      ),
                      Text(
                        'Address: ${(issue['address'] ?? 'N/A').toString()}',
                        style: const TextStyle(color: Color(0xFF94A3B8)),
                      ),
                      Text(
                        'GPS: ${(issue['latitude'] ?? 'N/A')}, ${(issue['longitude'] ?? 'N/A')}',
                        style: const TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: const Color(0xFF1E293B),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status Timeline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )),
                      const SizedBox(height: 8),
                      if (history.isEmpty)
                        const Text(
                          'No status history available yet.',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      ...history.map((item) {
                        final m = item as Map<String, dynamic>;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.check_circle, color: Color(0xFF22C55E)),
                          title: Text((m['status'] ?? '').toString()),
                          subtitle: Text(
                            '${m['updatedByName'] ?? 'System'} • ${m['timestamp'] ?? ''}',
                            style: const TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: const Color(0xFF1E293B),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Comments',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )),
                      const SizedBox(height: 8),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _service.streamIssueComments((issue['id'] ?? '').toString()),
                        builder: (context, snapshot) {
                          final comments = snapshot.data ?? [];
                          if (comments.isEmpty) {
                            return const Text(
                              'No comments yet.',
                              style: TextStyle(color: Color(0xFF94A3B8)),
                            );
                          }
                          return Column(
                            children: comments.map((c) {
                              final official = c['authorRole'] == 'city_authority';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: official
                                      ? const Color(0xFF1D4ED8).withValues(alpha: 0.25)
                                      : const Color(0xFF334155),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: ListTile(
                                  title: Text(
                                    (c['authorName'] ?? 'User').toString(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    (c['text'] ?? '').toString(),
                                    style: const TextStyle(color: Color(0xFFE2E8F0)),
                                  ),
                                  trailing: official
                                      ? const Chip(
                                          label: Text('Official Update'),
                                          visualDensity: VisualDensity.compact,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _commentCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Add comment/update',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () async {
                              final text = _commentCtrl.text.trim();
                              if (text.isEmpty) return;
                              try {
                                await _service.addIssueComment(
                                  issueId: (issue['id'] ?? '').toString(),
                                  comment: text,
                                );
                                _commentCtrl.clear();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Comment posted.')),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed: $e')),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 72),
            ],
          ),
          if (_saving)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: status == 'Done'
          ? const SizedBox(height: 0)
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : () => _showStatusDialog(issue),
                  icon: const Icon(Icons.track_changes),
                  label: const Text('Update Status'),
                ),
              ),
            ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(text),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Recognized':
        return const Color(0xFFF59E0B);
      case 'In Work':
        return const Color(0xFF0EA5E9);
      case 'Done':
        return const Color(0xFF22C55E);
      case 'Escalated':
        return const Color(0xFFEF4444);
      case 'Invalid':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}
