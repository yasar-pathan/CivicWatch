import 'package:civic_watch/models/user_model.dart';
import 'package:civic_watch/services/state_authority_service.dart';
import 'package:civic_watch/views/authority/state/screens/edit_city_authority_screen.dart';
import 'package:flutter/material.dart';

class CityAuthorityDetailScreen extends StatelessWidget {
  const CityAuthorityDetailScreen({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final service = StateAuthorityService();

    return Scaffold(
      appBar: AppBar(title: const Text('City Authority Detail')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: const Color(0xFF1E293B),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF334155),
                child: Text((user.name?.isNotEmpty ?? false) ? user.name![0] : 'C'),
              ),
              title: Text(user.name ?? 'Unknown', style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                '${user.email}\n${user.phone ?? 'N/A'}',
                style: const TextStyle(color: Colors.white70),
              ),
              isThreeLine: true,
            ),
          ),
          _tile('City', user.city),
          _tile('State', user.state),
          _tile('Employee ID', user.governmentId),
          _tile('Department', user.department),
          _tile('Office Address', user.officeAddress),
          _tile('Status', user.isActive ? 'Active' : 'Inactive'),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditCityAuthorityScreen(user: user)),
            ),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Information'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              if (user.isActive) {
                await service.deactivateCityAuthority(user.uid);
              } else {
                await service.activateCityAuthority(user.uid);
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(user.isActive ? 'Deactivated' : 'Activated')),
              );
            },
            icon: Icon(user.isActive ? Icons.block : Icons.check_circle),
            label: Text(user.isActive ? 'Deactivate' : 'Activate'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final txt = TextEditingController();
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  title: const Text('Delete City Authority'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Type DELETE and reason to confirm.'),
                      const SizedBox(height: 8),
                      TextField(controller: txt, decoration: const InputDecoration(hintText: 'Type DELETE', border: OutlineInputBorder())),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (ok != true || txt.text.trim() != 'DELETE') return;

              await service.deleteCityAuthorityFirestoreOnly(user.uid, reason: 'Deleted by state authority');
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('City Authority deleted (Firestore only).')),
              );
            },
            icon: const Icon(Icons.delete),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            label: const Text('Delete Account'),
          ),
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
