import 'package:civic_watch/models/user_model.dart';
import 'package:civic_watch/services/state_authority_service.dart';
import 'package:civic_watch/views/authority/state/screens/city_authority_detail_screen.dart';
import 'package:civic_watch/views/authority/state/screens/create_city_authority_screen.dart';
import 'package:flutter/material.dart';

class StateCityAuthoritiesTab extends StatefulWidget {
  const StateCityAuthoritiesTab({super.key});

  @override
  State<StateCityAuthoritiesTab> createState() => _StateCityAuthoritiesTabState();
}

class _StateCityAuthoritiesTabState extends State<StateCityAuthoritiesTab> {
  final _service = StateAuthorityService();
  String _search = '';
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name, email, city',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _filter,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                ],
                onChanged: (v) => setState(() => _filter = v ?? 'All'),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  tooltip: 'Add City Authority',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateCityAuthorityScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _service.getCityAuthorities(search: _search, filter: _filter),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Failed: ${snapshot.error}'));
              }

              final users = snapshot.data ?? [];
              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No City Authorities yet.'),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateCityAuthorityScreen()),
                        ),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Create First City Authority'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final u = users[index];
                  return Card(
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF334155),
                        child: Text((u.name?.isNotEmpty ?? false) ? u.name![0].toUpperCase() : 'C'),
                      ),
                      title: Text(u.name ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        '${u.city ?? 'N/A'} • ${u.email}\n${u.isActive ? 'Active' : 'Inactive'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      isThreeLine: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CityAuthorityDetailScreen(user: u),
                        ),
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
}
