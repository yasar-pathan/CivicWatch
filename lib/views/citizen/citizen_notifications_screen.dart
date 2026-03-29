import 'package:civic_watch/models/notification_model.dart';
import 'package:civic_watch/services/notification_navigation_service.dart';
import 'package:civic_watch/services/notification_service.dart';
import 'package:flutter/material.dart';

class CitizenNotificationsScreen extends StatelessWidget {
  const CitizenNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = NotificationService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => service.markAllAsRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: service.streamMyNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Failed: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              final isRead = item.read;

              return Card(
                color: isRead
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF1D4ED8).withValues(alpha: 0.2),
                child: ListTile(
                  onTap: () => NotificationNavigationService.openFromNotification(
                    context,
                    item,
                  ),
                  title: Text(item.title),
                  subtitle: Text(item.body),
                  trailing: isRead
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.mark_email_read),
                          onPressed: () => service.markAsRead(item.id),
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
