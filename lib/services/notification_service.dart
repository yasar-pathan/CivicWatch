import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:civic_watch/models/notification_model.dart';

class NotificationService {
  NotificationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _notificationsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('notifications');
  }

  Stream<List<AppNotification>> streamMyNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _notificationsRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(AppNotification.fromDoc).toList());
  }

  Stream<int> streamMyUnreadCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _notificationsRef(uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _notificationsRef(uid).doc(notificationId).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllAsRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final docs = await _notificationsRef(uid).where('read', isEqualTo: false).get();
    final batch = _firestore.batch();
    for (final doc in docs.docs) {
      batch.update(doc.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> createNotificationForUser({
    required String recipientUserId,
    required String title,
    required String body,
    required String type,
    String? issueId,
    String? actorId,
    String? route,
    Map<String, dynamic>? metadata,
  }) async {
    await _notificationsRef(recipientUserId).add({
      'title': title,
      'body': body,
      'type': type,
      'read': false,
      'recipientId': recipientUserId,
      'issueId': issueId,
      'actorId': actorId,
      'route': route,
      'metadata': metadata ?? <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createNotificationForUsers({
    required Iterable<String> recipientUserIds,
    required String title,
    required String body,
    required String type,
    String? issueId,
    String? actorId,
    String? route,
    Map<String, dynamic>? metadata,
  }) async {
    final ids = recipientUserIds.where((e) => e.trim().isNotEmpty).toSet();
    if (ids.isEmpty) return;

    final batch = _firestore.batch();
    for (final uid in ids) {
      final ref = _notificationsRef(uid).doc();
      batch.set(ref, {
        'title': title,
        'body': body,
        'type': type,
        'read': false,
        'recipientId': uid,
        'issueId': issueId,
        'actorId': actorId,
        'route': route,
        'metadata': metadata ?? <String, dynamic>{},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
