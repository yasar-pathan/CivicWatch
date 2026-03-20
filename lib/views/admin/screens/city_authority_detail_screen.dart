import 'package:civic_watch/models/user_model.dart';
import 'package:flutter/material.dart';

class CityAuthorityDetailScreen extends StatelessWidget {
  const CityAuthorityDetailScreen({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('City Authority Details')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: const Color(0xFF1E293B),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF334155),
                child: Text((user.name?.isNotEmpty ?? false)
                    ? user.name![0].toUpperCase()
                    : 'C'),
              ),
              title: Text(user.name ?? 'Unknown',
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text('${user.city ?? 'N/A'}, ${user.state ?? 'N/A'}\n${user.email}',
                  style: const TextStyle(color: Colors.white70)),
              isThreeLine: true,
            ),
          ),
          _tile('Phone', user.phone),
          _tile('Status', user.status),
          _tile('Active', user.isActive ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  Widget _tile(String title, String? value) {
    return Card(
      color: const Color(0xFF1E293B),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white70)),
        subtitle: Text(value ?? 'N/A', style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
