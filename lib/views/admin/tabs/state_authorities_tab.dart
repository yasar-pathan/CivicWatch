import 'package:civic_watch/models/user_model.dart';
import 'package:civic_watch/services/admin_service.dart';
import 'package:civic_watch/utils/password_generator.dart';
import 'package:civic_watch/views/admin/screens/state_authority_detail_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class StateAuthoritiesTab extends StatefulWidget {
  const StateAuthoritiesTab({super.key});

  @override
  State<StateAuthoritiesTab> createState() => _StateAuthoritiesTabState();
}

class _StateAuthoritiesTabState extends State<StateAuthoritiesTab> {
  final AdminService _adminService = AdminService();
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _sortBy = 'Name (A-Z)';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.blueAccent,
                decoration: const InputDecoration(
                  labelText: 'Search by name, email, state, employee ID',
                  labelStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.search, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _statusFilter,
                      decoration: const InputDecoration(
                        labelText: 'Filter',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(value: 'Active', child: Text('Active')),
                        DropdownMenuItem(
                            value: 'Inactive', child: Text('Inactive')),
                      ],
                      onChanged: (value) {
                        setState(() => _statusFilter = value ?? 'All');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _sortBy,
                      decoration: const InputDecoration(
                        labelText: 'Sort',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Name (A-Z)', child: Text('Name (A-Z)')),
                        DropdownMenuItem(
                            value: 'Name (Z-A)', child: Text('Name (Z-A)')),
                        DropdownMenuItem(value: 'State', child: Text('State')),
                        DropdownMenuItem(
                            value: 'Recently Created',
                            child: Text('Recently Created')),
                      ],
                      onChanged: (value) {
                        setState(() => _sortBy = value ?? 'Name (A-Z)');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _adminService.getAllStateAuthorities(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                final raw = snapshot.error.toString().toLowerCase();
                final message = raw.contains('permission-denied')
                    ? 'State authorities are blocked by Firestore rules. Publish admin rules and retry.'
                    : raw.contains('failed-precondition')
                        ? 'A Firestore index is required for this query. Create it from Firebase console.'
                        : 'Unable to load state authorities.';
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              }

              final authorities = snapshot.data ?? [];
              var filtered = authorities.where((auth) {
                final name = auth.name?.toLowerCase() ?? '';
                final email = auth.email.toLowerCase();
                final state = auth.state?.toLowerCase() ?? '';
                final employeeId = auth.governmentId?.toLowerCase() ?? '';
                final matchesSearch = name.contains(_searchQuery) ||
                    email.contains(_searchQuery) ||
                    state.contains(_searchQuery) ||
                    employeeId.contains(_searchQuery);

                final matchesFilter = _statusFilter == 'All' ||
                    (_statusFilter == 'Active' && auth.isActive) ||
                    (_statusFilter == 'Inactive' && !auth.isActive);

                return matchesSearch && matchesFilter;
              }).toList();

              if (_sortBy == 'Name (A-Z)') {
                filtered.sort((a, b) =>
                    (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));
              } else if (_sortBy == 'Name (Z-A)') {
                filtered.sort((a, b) =>
                    (b.name ?? '').toLowerCase().compareTo((a.name ?? '').toLowerCase()));
              } else if (_sortBy == 'State') {
                filtered.sort((a, b) =>
                    (a.state ?? '').toLowerCase().compareTo((b.state ?? '').toLowerCase()));
              } else if (_sortBy == 'Recently Created') {
                filtered.sort((a, b) {
                  final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bd.compareTo(ad);
                });
              }

              if (filtered.isEmpty) {
                return const Center(child: Text('No authorities match.'));
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final auth = filtered[index];
                  return Card(
                    color: const Color(0xFF1E293B),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Colors.white10),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF334155),
                        child: Text(auth.name?[0] ?? 'A'),
                      ),
                      title: Text(
                        auth.name ?? 'Unknown',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${auth.state ?? 'N/A'} • ${auth.email}\nID: ${auth.governmentId ?? 'N/A'}',
                        style: const TextStyle(color: Colors.white70),
                        maxLines: 2,
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'view') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StateAuthorityDetailScreen(user: auth),
                              ),
                            );
                          } else if (value == 'deactivate') {
                            _adminService.deactivateUser(auth.uid).then((_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Account deactivated')),
                              );
                            }).catchError((e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Action failed: $e')),
                              );
                            });
                          } else if (value == 'activate') {
                            _adminService.activateUser(auth.uid).then((_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Account activated')),
                              );
                            }).catchError((e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Action failed: $e')),
                              );
                            });
                          } else if (value == 'reset_password') {
                            final generated = PasswordGenerator.generate(length: 12);
                            Clipboard.setData(ClipboardData(text: generated));
                            _adminService
                                .markPasswordReset(auth.uid, method: 'auto')
                                .then((_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Password reset metadata updated. New password copied: $generated'),
                                ),
                              );
                            }).catchError((e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Reset failed: $e')),
                              );
                            });
                          } else if (value == 'delete') {
                            _confirmDelete(context, auth);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Text('View Details'),
                          ),
                          if (auth.isActive)
                            const PopupMenuItem(
                              value: 'deactivate',
                              child: Text('Deactivate'),
                            )
                          else
                            const PopupMenuItem(
                              value: 'activate',
                              child: Text('Activate'),
                            ),
                          const PopupMenuItem(
                            value: 'reset_password',
                            child: Text('Reset Password'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Account'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, UserModel auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Account?'),
        content: Text(
          'Delete ${auth.name ?? 'this user'} from Firestore? This does not delete Firebase Auth from client-side.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await _adminService.deleteStateAuthorityData(
        auth.uid,
        reason: 'Deleted by admin from app panel',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted from Firestore.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }
}
