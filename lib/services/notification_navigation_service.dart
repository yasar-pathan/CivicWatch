import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:civic_watch/models/notification_model.dart';
import 'package:civic_watch/views/authority/city/screens/city_issue_detail_screen.dart';
import 'package:civic_watch/views/authority/city/screens/city_notifications_screen.dart';
import 'package:civic_watch/views/authority/state/screens/escalated_issue_detail_screen.dart';
import 'package:civic_watch/views/authority/state/screens/state_notifications_screen.dart';
import 'package:civic_watch/views/admin/screens/admin_notifications_screen.dart';
import 'package:civic_watch/views/citizen/citizen_notifications_screen.dart';
import 'package:civic_watch/views/citizen/issue_detail_screen.dart';

class NotificationNavigationService {
  NotificationNavigationService._();

  static Future<void> openFromNotification(
    BuildContext context,
    AppNotification notification,
  ) async {
    await openFromPayload(
      context,
      issueId: notification.issueId,
      route: notification.route,
    );
  }

  static Future<void> openFromPayload(
    BuildContext context, {
    String? issueId,
    String? route,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};
    final role = (userData['role'] ?? 'citizen').toString();

    final normalizedIssueId =
        (issueId ?? _extractIssueId(route)).toString().trim();

    if (normalizedIssueId.isNotEmpty) {
      final issueDoc = await FirebaseFirestore.instance
          .collection('issues')
          .doc(normalizedIssueId)
          .get();
      if (issueDoc.exists && issueDoc.data() != null) {
        final issue = {'id': issueDoc.id, ...issueDoc.data()!};
        if (!context.mounted) return;

        if (role == 'city_authority') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CityIssueDetailScreen(issue: issue),
            ),
          );
          return;
        }

        if (role == 'state_authority') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EscalatedIssueDetailScreen(issue: issue),
            ),
          );
          return;
        }

        if (role == 'citizen') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IssueDetailScreen(
                issueId: issueDoc.id,
                data: issue,
              ),
            ),
          );
          return;
        }
      }
    }

    if (!context.mounted) return;
    if (role == 'admin') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()),
      );
      return;
    }

    if (role == 'state_authority') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StateNotificationsScreen()),
      );
      return;
    }

    if (role == 'city_authority') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CityNotificationsScreen()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CitizenNotificationsScreen()),
    );
  }

  static String _extractIssueId(String? route) {
    final value = (route ?? '').trim();
    if (value.startsWith('/issue/')) {
      return value.replaceFirst('/issue/', '').trim();
    }
    return '';
  }
}
