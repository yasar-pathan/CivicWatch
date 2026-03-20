import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CityNotificationsScreen extends StatelessWidget {
  const CityNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              final docs = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('notifications')
                  .get();
              for (final d in docs.docs) {
                await d.reference.update({'read': true});
              }
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index].data();
              final isRead = d['read'] == true;
              return Card(
                color: isRead
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF1D4ED8).withValues(alpha: 0.2),
                child: ListTile(
                  title: Text((d['title'] ?? 'Notification').toString()),
                  subtitle: Text((d['body'] ?? '').toString()),
                  trailing: isRead
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.mark_email_read),
                          onPressed: () => docs[index].reference.update({'read': true}),
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
