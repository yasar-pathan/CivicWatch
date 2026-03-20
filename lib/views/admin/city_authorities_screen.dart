import 'package:civic_watch/models/user_model.dart';
import 'package:civic_watch/views/admin/screens/city_authority_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CityAuthoritiesScreen extends StatefulWidget {
  const CityAuthoritiesScreen({super.key});

  @override
  State<CityAuthoritiesScreen> createState() => _CityAuthoritiesScreenState();
}

class _CityAuthoritiesScreenState extends State<CityAuthoritiesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _groupBy = 'State';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('City Authorities')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _groupBy,
                  decoration: const InputDecoration(
                    labelText: 'Group by',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'State', child: Text('State')),
                    DropdownMenuItem(value: 'City', child: Text('City')),
                    DropdownMenuItem(value: 'Status', child: Text('Status')),
                  ],
                  onChanged: (value) {
                    setState(() => _groupBy = value ?? 'State');
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Search City Authority',
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
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase()),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'city_authority')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final raw = snapshot.error.toString().toLowerCase();
                  final message = raw.contains('permission-denied')
                      ? 'City authorities are blocked by Firestore rules. Publish admin rules and retry.'
                      : raw.contains('failed-precondition')
                          ? 'A Firestore index is required for this query. Create it from Firebase console.'
                          : 'Unable to load city authorities.';
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

                final docs = snapshot.data?.docs ?? [];

                // Group by State
                final Map<String, List<UserModel>> grouped = {};
                for (var doc in docs) {
                  final user =
                      UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                  if (_searchQuery.isNotEmpty) {
                    final name = user.name?.toLowerCase() ?? '';
                    final city = user.city?.toLowerCase() ?? '';
                    if (!name.contains(_searchQuery) && !city.contains(_searchQuery)) {
                      continue;
                    }
                  }

                  String groupKey;
                  if (_groupBy == 'City') {
                    groupKey = user.city ?? 'Unknown City';
                  } else if (_groupBy == 'Status') {
                    groupKey = user.isActive ? 'Active' : 'Inactive';
                  } else {
                    groupKey = user.state ?? 'Unknown State';
                  }

                  if (!grouped.containsKey(groupKey)) {
                    grouped[groupKey] = [];
                  }
                  grouped[groupKey]!.add(user);
                }

                if (grouped.isEmpty) {
                  return const Center(child: Text('No city authorities found.'));
                }

                final sortedStates = grouped.keys.toList()..sort();

                return ListView.builder(
                  itemCount: sortedStates.length,
                  itemBuilder: (context, index) {
                    final state = sortedStates[index];
                    final users = grouped[state]!;

                    return ExpansionTile(
                      collapsedBackgroundColor: const Color(0xFF1E293B),
                      backgroundColor: const Color(0xFF1E293B),
                      iconColor: Colors.white,
                      collapsedIconColor: Colors.white,
                      title: Text(
                        '$state (${users.length})',
                        style: const TextStyle(color: Colors.white),
                      ),
                      children: users
                          .map((user) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF334155),
                                  child: Text(user.name?[0] ?? 'C'),
                                ),
                                title: Text(
                                  user.name ?? 'Unknown',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  '${user.city ?? 'N/A'} • ${user.email}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CityAuthorityDetailScreen(user: user),
                                    ),
                                  );
                                },
                              ))
                          .toList(),
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
