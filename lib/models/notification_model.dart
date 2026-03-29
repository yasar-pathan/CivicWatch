import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool read;
  final DateTime? createdAt;
  final String? recipientId;
  final String? actorId;
  final String? issueId;
  final String? route;
  final Map<String, dynamic> metadata;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
    this.recipientId,
    this.actorId,
    this.issueId,
    this.route,
    this.metadata = const {},
  });

  factory AppNotification.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final created = data['createdAt'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is DateTime) {
      createdAt = created;
    }

    return AppNotification(
      id: doc.id,
      title: (data['title'] ?? 'Notification').toString(),
      body: (data['body'] ?? '').toString(),
      type: (data['type'] ?? 'general').toString(),
      read: data['read'] == true,
      createdAt: createdAt,
      recipientId: data['recipientId']?.toString(),
      actorId: data['actorId']?.toString(),
      issueId: data['issueId']?.toString(),
      route: data['route']?.toString(),
      metadata: (data['metadata'] is Map<String, dynamic>)
          ? data['metadata'] as Map<String, dynamic>
          : const {},
    );
  }
}
