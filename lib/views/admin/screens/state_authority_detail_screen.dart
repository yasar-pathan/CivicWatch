import 'package:civic_watch/models/user_model.dart';
import 'package:civic_watch/services/admin_service.dart';
import 'package:civic_watch/views/admin/screens/edit_state_authority_screen.dart';
import 'package:flutter/material.dart';

class StateAuthorityDetailScreen extends StatelessWidget {
  const StateAuthorityDetailScreen({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('State Authority Details')),
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
                    : 'S'),
              ),
              title: Text(user.name ?? 'Unknown',
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                '${user.email}\n${user.phone ?? 'N/A'}',
                style: const TextStyle(color: Colors.white70),
              ),
              isThreeLine: true,
            ),
          ),
          _infoTile('State', user.state),
          _infoTile('Government ID', user.governmentId),
          _infoTile('Department', user.department),
          _infoTile('Office Address', user.officeAddress),
          _infoTile('Status', user.isActive ? 'Active' : 'Inactive'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditStateAuthorityScreen(user: user),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Information'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final service = AdminService();
              if (user.isActive) {
                await service.deactivateUser(user.uid);
              } else {
                await service.activateUser(user.uid);
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(user.isActive ? 'Deactivated' : 'Activated')),
              );
            },
            icon: Icon(user.isActive ? Icons.block : Icons.check_circle),
            label: Text(user.isActive ? 'Deactivate Account' : 'Activate Account'),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String? value) {
    return Card(
      color: const Color(0xFF1E293B),
      child: ListTile(
        title: Text(label, style: const TextStyle(color: Colors.white70)),
        subtitle: Text(value ?? 'N/A', style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
