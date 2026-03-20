import 'package:civic_watch/services/state_authority_service.dart';
import 'package:flutter/material.dart';

class NonEscalatedIssuesScreen extends StatefulWidget {
  const NonEscalatedIssuesScreen({super.key});

  @override
  State<NonEscalatedIssuesScreen> createState() => _NonEscalatedIssuesScreenState();
}

class _NonEscalatedIssuesScreenState extends State<NonEscalatedIssuesScreen> {
  final _service = StateAuthorityService();
  String _city = 'All';
  String _status = 'All';
  final String _category = 'All';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Non-Escalated Issues')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                FutureBuilder<List<String>>(
                  future: _service.getStateCities(),
                  builder: (context, snapshot) {
                    final cities = ['All', ...(snapshot.data ?? [])];
                    if (!cities.contains(_city)) _city = 'All';
                    return DropdownButtonFormField<String>(
                      initialValue: _city,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                      items: cities
                          .map<DropdownMenuItem<String>>(
                            (c) => DropdownMenuItem<String>(
                              value: c,
                              child: Text(c),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _city = v ?? 'All'),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          DropdownMenuItem(value: 'Reported', child: Text('Reported')),
                          DropdownMenuItem(value: 'Recognized', child: Text('Recognized')),
                          DropdownMenuItem(value: 'In Work', child: Text('In Work')),
                          DropdownMenuItem(value: 'Done', child: Text('Done')),
                        ],
                        onChanged: (v) => setState(() => _status = v ?? 'All'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.getIssues(
                escalated: false,
                selectedCity: _city,
                statusFilter: _status,
                categoryFilter: _category,
                query: _search,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Failed: ${snapshot.error}'));
                }

                final issues = snapshot.data ?? [];
                if (issues.isEmpty) {
                  return const Center(child: Text('No non-escalated issues found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: issues.length,
                  itemBuilder: (context, index) {
                    final issue = issues[index];
                    final status = (issue['status'] ?? 'N/A').toString();
                    return Card(
                      color: const Color(0xFF1E293B),
                      child: ListTile(
                        title: Text(
                          (issue['title'] ?? 'Untitled').toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${issue['City'] ?? issue['city'] ?? 'N/A'} • ${issue['category'] ?? 'N/A'}\nStatus: $status',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          '#${issue['id']}',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
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
