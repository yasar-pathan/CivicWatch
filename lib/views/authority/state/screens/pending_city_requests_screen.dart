import 'package:civic_watch/models/user_model.dart';
import 'package:civic_watch/services/state_authority_service.dart';
import 'package:flutter/material.dart';

class PendingCityRequestsScreen extends StatelessWidget {
  const PendingCityRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = StateAuthorityService();
    return Scaffold(
      appBar: AppBar(title: const Text('Pending City Requests')),
      body: StreamBuilder<List<UserModel>>(
        stream: service.getPendingCityRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(
              child: Text(
                'No pending city authority requests.\n(If only state-created accounts are enabled, this is expected.)',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                color: const Color(0xFF1E293B),
                child: ListTile(
                  title: Text(user.name ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '${user.city ?? 'N/A'} • ${user.email}\nID: ${user.governmentId ?? 'N/A'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          await service.approveCityAuthority(user.uid);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('City Authority approved')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          final reasonController = TextEditingController();
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF1E293B),
                              title: const Text('Reject Request'),
                              content: TextField(
                                controller: reasonController,
                                decoration: const InputDecoration(
                                  hintText: 'Reason',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject')),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          await service.rejectCityAuthority(user.uid, reasonController.text.trim());
                          reasonController.dispose();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('City Authority rejected')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
