import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civic_watch/services/city_authority_service.dart';
import 'package:civic_watch/views/authority/city/screens/city_issue_detail_screen.dart';
import 'package:flutter/material.dart';

class CityIssuesListScreen extends StatefulWidget {
  const CityIssuesListScreen({
    super.key,
    this.embedded = false,
    this.initialStatus = 'All',
    this.onlyEscalated = false,
    this.onlyInvalid = false,
    this.title,
  });

  final bool embedded;
  final String initialStatus;
  final bool onlyEscalated;
  final bool onlyInvalid;
  final String? title;

  @override
  State<CityIssuesListScreen> createState() => _CityIssuesListScreenState();
}

class _CityIssuesListScreenState extends State<CityIssuesListScreen> {
  final _service = CityAuthorityService();
  static const Color _panel = Color(0xFF1E293B);
  static const Color _muted = Color(0xFF94A3B8);

  String _status = 'All';
  String _category = 'All';
  String _priority = 'All';
  String _dateRange = 'All';
  String _sort = 'Latest First';
  String _search = '';

  final Set<String> _selected = <String>{};
  int _visibleCount = 20;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _buildFilters(),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _service.streamCityIssues(
              status: _status,
              category: _category,
              priority: _priority,
              dateRange: _dateRange,
              sort: _sort,
              search: _search,
              onlyEscalated: widget.onlyEscalated,
              onlyInvalid: widget.onlyInvalid,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Failed: ${snapshot.error}'));
              }

              final allIssues = snapshot.data ?? [];
              final issues = allIssues.take(_visibleCount).toList();
              if (issues.isEmpty) {
                return const Center(
                  child: Text(
                    'No issues found. Great job keeping the city clean!',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return Column(
                children: [
                  if (_selected.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _panel,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_selected.length} selected',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _bulkUpdate('Recognized'),
                            child: const Text('Update Selected'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: issues.length + 1,
                      itemBuilder: (context, index) {
                        if (index == issues.length) {
                          if (allIssues.length <= issues.length) {
                            return const SizedBox(height: 6);
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 16),
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _visibleCount += 20);
                              },
                              child: const Text('Load More'),
                            ),
                          );
                        }

                        final issue = issues[index];
                        final id = (issue['id'] ?? '').toString();
                        final status = (issue['status'] ?? 'Reported').toString();
                        final daysPending = _daysPending(issue);
                        final warn = _escalationWarning(issue);

                        return Card(
                          color: _panel,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _selected.contains(id),
                                      side: const BorderSide(color: Colors.white38),
                                      onChanged: (_) {
                                        setState(() {
                                          if (_selected.contains(id)) {
                                            _selected.remove(id);
                                          } else {
                                            _selected.add(id);
                                          }
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: Text(
                                        (issue['title'] ?? 'Untitled').toString(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    _statusChip(status),
                                  ],
                                ),
                                if ((issue['photoUrl'] ?? '').toString().isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      issue['photoUrl'].toString(),
                                      width: double.infinity,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  (issue['description'] ?? '').toString(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 6,
                                  children: [
                                    Text(
                                      'Category: ${(issue['category'] ?? 'N/A')}',
                                      style: const TextStyle(color: _muted),
                                    ),
                                    Text(
                                      'Priority: ${(issue['priority'] ?? 'Medium')}',
                                      style: const TextStyle(color: _muted),
                                    ),
                                    Text(
                                      '👍 ${issue['upvotes'] ?? 0}',
                                      style: const TextStyle(color: _muted),
                                    ),
                                    Text(
                                      '💬 ${issue['commentCount'] ?? 0}',
                                      style: const TextStyle(color: _muted),
                                    ),
                                    Text(
                                      '⏱️ $daysPending days',
                                      style: const TextStyle(color: _muted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '📍 ${(issue['address'] ?? 'N/A').toString()}',
                                  style: const TextStyle(color: _muted),
                                ),
                                if (warn != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      warn,
                                      style: const TextStyle(color: Color(0xFFFCA5A5)),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CityIssueDetailScreen(issue: issue),
                                        ),
                                      ),
                                      child: const Text('View Details'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: status == 'Done'
                                          ? null
                                          : () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      CityIssueDetailScreen(issue: issue),
                                                ),
                                              ),
                                      child: const Text('Update Status'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );

    if (widget.embedded) return content;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Text(widget.title ?? 'All Issues'),
      ),
      body: content,
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Search by issue ID, description, location, citizen name',
              hintStyle: TextStyle(color: _muted),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFF0F172A),
              prefixIcon: Icon(Icons.search, color: _muted),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _dropdown(
                    'Status',
                    _status,
                    const [
                      'All',
                      'Reported',
                      'Recognized',
                      'In Work',
                      'Done',
                      'Escalated',
                      'Invalid'
                    ],
                    (v) => setState(() => _status = v),
                    width,
                  ),
                  _dropdown(
                    'Category',
                    _category,
                    const [
                      'All',
                      'Pothole',
                      'Sewage',
                      'Broken Infrastructure',
                      'Cleanliness',
                      'Street Lights',
                      'Others'
                    ],
                    (v) => setState(() => _category = v),
                    width,
                  ),
                  _dropdown(
                    'Priority',
                    _priority,
                    const ['All', 'High', 'Medium', 'Low'],
                    (v) => setState(() => _priority = v),
                    width,
                  ),
                  _dropdown(
                    'Date',
                    _dateRange,
                    const ['All', 'Today', 'Last 7 days', 'Last 30 days'],
                    (v) => setState(() => _dateRange = v),
                    width,
                  ),
                  _dropdown(
                    'Sort',
                    _sort,
                    const [
                      'Latest First',
                      'Oldest First',
                      'Priority High-Low',
                      'Priority Low-High'
                    ],
                    (v) => setState(() => _sort = v),
                    width,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        initialValue: items.contains(value) ? value : items.first,
        isExpanded: true,
        style: const TextStyle(color: Colors.white),
        dropdownColor: const Color(0xFF0F172A),
        iconEnabledColor: _muted,
        decoration: const InputDecoration(
          labelStyle: TextStyle(color: _muted),
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Color(0xFF0F172A),
        ).copyWith(labelText: label),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        selectedItemBuilder: (context) => items
            .map(
              (e) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  e,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
            .toList(),
        onChanged: (v) => onChanged(v ?? items.first),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'Recognized':
        color = const Color(0xFFF59E0B);
        break;
      case 'In Work':
        color = const Color(0xFF0EA5E9);
        break;
      case 'Done':
        color = const Color(0xFF22C55E);
        break;
      case 'Escalated':
        color = const Color(0xFFEF4444);
        break;
      case 'Invalid':
        color = const Color(0xFF64748B);
        break;
      default:
        color = const Color(0xFF9CA3AF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  int _daysPending(Map<String, dynamic> issue) {
    final t = issue['lastStatusUpdateAt'] as Timestamp? ??
        issue['statusUpdatedAt'] as Timestamp? ??
        issue['updatedAt'] as Timestamp? ??
        issue['createdAt'] as Timestamp?;
    if (t == null) return 0;
    return DateTime.now().difference(t.toDate()).inDays;
  }

  String? _escalationWarning(Map<String, dynamic> issue) {
    final status = (issue['status'] ?? '').toString();
    final days = _daysPending(issue);
    if (status == 'Recognized') {
      final left = 7 - days;
      if (left <= 2) return '⚠️ Will escalate in ${left.clamp(0, 2)} day(s)';
    }
    if (status == 'In Work') {
      final left = 14 - days;
      if (left <= 2) return '⚠️ Will escalate in ${left.clamp(0, 2)} day(s)';
    }
    return null;
  }

  Future<void> _bulkUpdate(String status) async {
    if (_selected.isEmpty) return;

    int success = 0;
    int failed = 0;
    for (final id in _selected) {
      try {
        await _service.updateIssueStatus(issueId: id, newStatus: status);
        success++;
      } catch (_) {
        failed++;
      }
    }

    if (!mounted) return;
    setState(() => _selected.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bulk update done: $success success, $failed failed')),
    );
  }
}
