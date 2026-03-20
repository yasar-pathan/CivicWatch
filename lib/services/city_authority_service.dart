import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:civic_watch/models/user_model.dart';
import 'package:civic_watch/utils/location_normalizer.dart';

class CityAuthorityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserModel> getCurrentCityAuthorityProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) throw Exception('City authority profile not found');
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<Map<String, String>> _getCityScope() async {
    final profile = await getCurrentCityAuthorityProfile();
    final city = LocationNormalizer.toTitleCase(profile.city);
    final cityNormalized =
        (profile.city == null || profile.city!.trim().isEmpty)
            ? ''
            : LocationNormalizer.normalize(profile.city);
    return {
      'city': city,
      'cityNormalized': cityNormalized,
      'state': profile.state ?? '',
      'uid': profile.uid,
      'name': profile.name ?? 'City Authority',
    };
  }

  bool _isEscalated(Map<String, dynamic> issue) {
    final status = (issue['status'] ?? '').toString().toLowerCase();
    if (issue['escalated'] == true || status == 'escalated') return true;

    final baseline = issue['lastStatusUpdateAt'] as Timestamp? ??
        issue['statusUpdatedAt'] as Timestamp? ??
        issue['updatedAt'] as Timestamp? ??
        issue['createdAt'] as Timestamp?;
    final days = _daysSince(baseline);

    // Auto escalation visibility rules.
    if (status == 'recognized' && days >= 7) return true;
    if (status == 'in work' && days >= 14) return true;
    return false;
  }

  int _daysSince(Timestamp? ts) {
    if (ts == null) return 0;
    return DateTime.now().difference(ts.toDate()).inDays;
  }

  String _normalizePriority(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Medium';
    return v;
  }

  int _priorityWeight(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 2;
    }
  }

  bool _isMyCityIssue(Map<String, dynamic> issue, Map<String, String> scope) {
    final issueCity = LocationNormalizer.toTitleCase(
      (issue['City'] ?? issue['city'] ?? '').toString(),
    );
    final issueCityNormalized =
        (issue['cityNormalized'] ?? '').toString().trim().toLowerCase();

    return issueCityNormalized == scope['cityNormalized'] ||
        issueCity == scope['city'];
  }

  Stream<List<Map<String, dynamic>>> streamCityIssues({
    String status = 'All',
    String category = 'All',
    String priority = 'All',
    String dateRange = 'All',
    String search = '',
    bool onlyEscalated = false,
    bool onlyInvalid = false,
    String sort = 'Latest First',
  }) async* {
    final scope = await _getCityScope();
    final cityNormalized = scope['cityNormalized'] ?? '';

    // Keep this query index-light by avoiding server-side orderBy; we sort client-side.
    Query<Map<String, dynamic>> query = _firestore.collection('issues');

    if (cityNormalized.isNotEmpty) {
      query = query.where('cityNormalized', isEqualTo: cityNormalized);
    } else {
      query = query.where('City', isEqualTo: scope['city']);
    }

    yield* query.snapshots().map((snapshot) {
      var issues = snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();

      issues = issues.where((issue) {
        if (!_isMyCityIssue(issue, scope)) return false;

        final issueStatus = (issue['status'] ?? '').toString();
        final issueCategory = (issue['category'] ?? '').toString();
        final issuePriority = _normalizePriority(issue['priority']?.toString());
        final isEsc = _isEscalated(issue);

        if (onlyEscalated && !isEsc) return false;
        if (onlyInvalid && issueStatus != 'Invalid') return false;
        if (!onlyInvalid && issueStatus == 'Invalid') return false;

        if (status != 'All' && issueStatus != status) return false;
        if (category != 'All' && issueCategory != category) return false;
        if (priority != 'All' && issuePriority != priority) return false;

        final createdAt = issue['createdAt'] as Timestamp?;
        if (dateRange != 'All' && createdAt != null) {
          final now = DateTime.now();
          final dt = createdAt.toDate();
          if (dateRange == 'Today') {
            if (dt.year != now.year || dt.month != now.month || dt.day != now.day) {
              return false;
            }
          }
          if (dateRange == 'Last 7 days' && now.difference(dt).inDays > 7) {
            return false;
          }
          if (dateRange == 'Last 30 days' && now.difference(dt).inDays > 30) {
            return false;
          }
        }

        final q = search.trim().toLowerCase();
        if (q.isNotEmpty) {
          final id = (issue['id'] ?? '').toString().toLowerCase();
          final title = (issue['title'] ?? '').toString().toLowerCase();
          final desc = (issue['description'] ?? '').toString().toLowerCase();
          final addr = (issue['address'] ?? '').toString().toLowerCase();
          final reporter = (issue['reporterName'] ?? '').toString().toLowerCase();
          if (!id.contains(q) &&
              !title.contains(q) &&
              !desc.contains(q) &&
              !addr.contains(q) &&
              !reporter.contains(q)) {
            return false;
          }
        }

        return true;
      }).toList();

      issues.sort((a, b) {
        final at = a['createdAt'] as Timestamp?;
        final bt = b['createdAt'] as Timestamp?;
        final ap = _priorityWeight(_normalizePriority(a['priority']?.toString()));
        final bp = _priorityWeight(_normalizePriority(b['priority']?.toString()));

        if (sort == 'Oldest First') {
          if (at == null && bt == null) return 0;
          if (at == null) return -1;
          if (bt == null) return 1;
          return at.compareTo(bt);
        }
        if (sort == 'Priority High-Low') return bp.compareTo(ap);
        if (sort == 'Priority Low-High') return ap.compareTo(bp);

        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });

      return issues;
    });
  }

  Stream<Map<String, int>> streamNavCounts() async* {
    final stream = streamCityIssues();
    yield* stream.map((issues) {
      int pending = 0;
      int escalated = 0;
      for (final issue in issues) {
        final status = (issue['status'] ?? '').toString();
        if (status == 'Reported' || status == 'Recognized') pending++;
        if (_isEscalated(issue)) escalated++;
      }
      return {
        'pending': pending,
        'escalated': escalated,
      };
    });
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final issues = await streamCityIssues().first;

    int reported = 0;
    int recognized = 0;
    int inWork = 0;
    int done = 0;
    int escalated = 0;
    int invalid = 0;
    int resolvedThisMonth = 0;
    final categories = <String, int>{
      'Pothole': 0,
      'Sewage': 0,
      'Broken Infrastructure': 0,
      'Cleanliness': 0,
      'Street Lights': 0,
      'Others': 0,
    };

    final now = DateTime.now();
    double totalResolutionDays = 0;
    int resolutionCount = 0;

    for (final issue in issues) {
      final status = (issue['status'] ?? '').toString();
      final category = (issue['category'] ?? 'Others').toString();
      final createdAt = issue['createdAt'] as Timestamp?;
      final doneAt = issue['doneAt'] as Timestamp?;

      if (status == 'Reported') reported++;
      if (status == 'Recognized') recognized++;
      if (status == 'In Work') inWork++;
      if (status == 'Done') {
        done++;
        if (doneAt != null) {
          final d = doneAt.toDate();
          if (d.year == now.year && d.month == now.month) {
            resolvedThisMonth++;
          }
        }
      }
      if (status == 'Invalid') invalid++;
      if (_isEscalated(issue)) escalated++;

      categories[category] = (categories[category] ?? 0) + 1;

      if (status == 'Done' && createdAt != null && doneAt != null) {
        totalResolutionDays +=
            doneAt.toDate().difference(createdAt.toDate()).inHours / 24.0;
        resolutionCount++;
      }
    }

    final avgResolution =
        resolutionCount == 0 ? 0 : (totalResolutionDays / resolutionCount);

    return {
      'totalIssues': issues.length,
      'reported': reported,
      'recognized': recognized,
      'inWork': inWork,
      'done': done,
      'escalated': escalated,
      'invalid': invalid,
      'resolvedThisMonth': resolvedThisMonth,
      'avgResolutionDays': avgResolution,
      'categories': categories,
    };
  }

  Future<List<Map<String, dynamic>>> getUrgentAlerts() async {
    final issues = await streamCityIssues().first;
    final alerts = <Map<String, dynamic>>[];

    for (final issue in issues) {
      final status = (issue['status'] ?? '').toString();
      if (status != 'Recognized' && status != 'In Work') continue;

      final baseline = issue['lastStatusUpdateAt'] as Timestamp? ??
          issue['statusUpdatedAt'] as Timestamp? ??
          issue['updatedAt'] as Timestamp? ??
          issue['createdAt'] as Timestamp?;

      final days = _daysSince(baseline);
      if ((status == 'Recognized' && days >= 5) ||
          (status == 'In Work' && days >= 12)) {
        final escalationAt = status == 'Recognized' ? 7 : 14;
        final countdown = (escalationAt - days).clamp(0, 999);
        alerts.add({
          ...issue,
          'daysPending': days,
          'countdown': countdown,
        });
      }
    }

    alerts.sort((a, b) =>
        (b['daysPending'] as int).compareTo(a['daysPending'] as int));
    return alerts;
  }

  Future<List<Map<String, dynamic>>> getRecentIssues({int limit = 10}) async {
    final issues = await streamCityIssues().first;
    return issues.take(limit).toList();
  }

  Stream<List<Map<String, dynamic>>> streamIssueComments(String issueId) {
    return _firestore
        .collection('issues')
        .doc(issueId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> addIssueComment({
    required String issueId,
    required String comment,
  }) async {
    final user = await getCurrentCityAuthorityProfile();
    final text = comment.trim();
    if (text.isEmpty) throw Exception('Comment cannot be empty.');
    if (text.length > 500) throw Exception('Comment limit is 500 characters.');

    await _firestore.collection('issues').doc(issueId).collection('comments').add({
      'text': text,
      'authorId': user.uid,
      'authorName': user.name ?? 'City Authority',
      'authorRole': 'city_authority',
      'officialUpdate': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('issues').doc(issueId).update({
      'commentCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await logActivity(
      action: 'comment_added',
      issueId: issueId,
      details: {'text': text},
    );
  }

  Future<String> uploadAfterPhoto({
    required String issueId,
    required File file,
    bool progressPhoto = false,
  }) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final name = progressPhoto ? 'progress_$stamp.jpg' : 'after_$stamp.jpg';
    final ref = FirebaseStorage.instance
        .ref()
        .child('issue_photos')
        .child(issueId)
        .child(name);
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  String? validateStatusTransition(String current, String target) {
    if (current == 'Done') {
      return 'Cannot change status of completed issue.';
    }

    if (current == 'Reported' && target != 'Recognized' && target != 'Invalid') {
      return 'Can only verify or mark as invalid.';
    }

    if (current == 'Recognized' && target != 'In Work') {
      return 'Must start work next.';
    }

    if (current == 'In Work' && target != 'Done') {
      return 'Can only mark as completed.';
    }

    if (current == target) {
      return 'Issue is already in $target status.';
    }

    return null;
  }

  Future<void> updateIssueStatus({
    required String issueId,
    required String newStatus,
    String? notes,
    String? invalidReason,
    String? afterPhotoUrl,
  }) async {
    final scope = await _getCityScope();
    final doc = await _firestore.collection('issues').doc(issueId).get();
    if (!doc.exists) throw Exception('Issue not found.');

    final issue = {'id': doc.id, ...doc.data()!};
    if (!_isMyCityIssue(issue, scope)) {
      throw Exception('You can only update issues from your assigned city.');
    }

    final current = (issue['status'] ?? 'Reported').toString();
    final err = validateStatusTransition(current, newStatus);
    if (err != null) throw Exception(err);

    if (newStatus == 'Done' && (afterPhotoUrl == null || afterPhotoUrl.isEmpty)) {
      throw Exception('After photo is required to mark issue as completed.');
    }

    final update = <String, dynamic>{
      'status': newStatus,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
      'lastStatusUpdateAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': scope['uid'],
      'updatedByRole': 'city_authority',
      'updatedByName': scope['name'],
      'notes': (notes ?? '').trim(),
      'escalated': false,
      'escalatedAt': FieldValue.delete(),
    };

    if (newStatus == 'Done') {
      update['doneAt'] = FieldValue.serverTimestamp();
      update['afterPhotoUrl'] = afterPhotoUrl;
    }

    if (newStatus == 'Invalid') {
      update['invalidReason'] = (invalidReason ?? '').trim();
      update['markedInvalidBy'] = scope['uid'];
      update['markedInvalidAt'] = FieldValue.serverTimestamp();
    }

    update['statusHistory'] = FieldValue.arrayUnion([
      {
        'status': newStatus,
        'timestamp': Timestamp.now(),
        'updatedBy': scope['uid'],
        'updatedByName': scope['name'],
        'role': 'city_authority',
        'notes': (notes ?? '').trim(),
      }
    ]);

    try {
      await _firestore.collection('issues').doc(issueId).update(update);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
            'Permission denied while updating issue. Ensure latest Firestore rules are deployed.');
      }
      rethrow;
    }

    await logActivity(
      action: 'status_updated',
      issueId: issueId,
      details: {
        'from': current,
        'to': newStatus,
        'notes': (notes ?? '').trim(),
      },
    );
  }

  Future<void> markIssueInvalid({
    required String issueId,
    required String reason,
    String? notes,
  }) async {
    final allowedReasons = {
      'Duplicate Report',
      'Fake Photo',
      'Not in Jurisdiction',
      'Resolved Already',
      'Other',
    };
    if (!allowedReasons.contains(reason)) {
      throw Exception('Invalid reason selected.');
    }

    await updateIssueStatus(
      issueId: issueId,
      newStatus: 'Invalid',
      invalidReason: reason,
      notes: notes,
    );
  }

  Future<Map<String, dynamic>> getCityAnalytics({String range = 'Last 30 days'}) async {
    final issues = await streamCityIssues(dateRange: range).first;
    final total = issues.length;
    if (total == 0) {
      return {
        'total': 0,
        'resolutionRate': 0.0,
        'escalationRate': 0.0,
        'performanceScore': 0,
        'statusCounts': <String, int>{},
        'categoryBreakdown': <String, Map<String, int>>{},
      };
    }

    int reported = 0;
    int recognized = 0;
    int inWork = 0;
    int done = 0;
    int escalated = 0;
    int invalid = 0;

    final category = <String, Map<String, int>>{};

    for (final issue in issues) {
      final status = (issue['status'] ?? '').toString();
      final cat = (issue['category'] ?? 'Others').toString();
      final isEsc = _isEscalated(issue);

      if (status == 'Reported') reported++;
      if (status == 'Recognized') recognized++;
      if (status == 'In Work') inWork++;
      if (status == 'Done') done++;
      if (status == 'Invalid') invalid++;
      if (isEsc) escalated++;

      category.putIfAbsent(cat, () => {
            'total': 0,
            'resolved': 0,
            'pending': 0,
          });
      category[cat]!['total'] = (category[cat]!['total'] ?? 0) + 1;
      if (status == 'Done') {
        category[cat]!['resolved'] = (category[cat]!['resolved'] ?? 0) + 1;
      } else {
        category[cat]!['pending'] = (category[cat]!['pending'] ?? 0) + 1;
      }
    }

    final resolutionRate = done / total * 100;
    final escalationRate = escalated / total * 100;
    final performanceScore = (resolutionRate - escalationRate).clamp(0, 100).round();

    return {
      'total': total,
      'resolutionRate': resolutionRate,
      'escalationRate': escalationRate,
      'performanceScore': performanceScore,
      'statusCounts': {
        'Reported': reported,
        'Recognized': recognized,
        'In Work': inWork,
        'Done': done,
        'Escalated': escalated,
        'Invalid': invalid,
      },
      'categoryBreakdown': category,
    };
  }

  Stream<List<Map<String, dynamic>>> streamActivityLogs({
    String type = 'All',
    int limit = 200,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('activity_logs')
        .where('actorRole', isEqualTo: 'city_authority')
        .where('actorId', isEqualTo: _auth.currentUser?.uid)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    return query.snapshots().map((snapshot) {
      var logs = snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      if (type != 'All') {
        logs = logs.where((l) => (l['action'] ?? '') == type).toList();
      }
      return logs;
    });
  }

  Future<void> updateNotificationPreferences({
    required Map<String, dynamic> prefs,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    await _firestore.collection('users').doc(uid).update({
      'notificationPrefs': prefs,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception('Not authenticated');

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);

    await _firestore.collection('users').doc(user.uid).update({
      'passwordChangedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await logActivity(action: 'password_changed');
  }

  Future<void> logActivity({
    required String action,
    String? issueId,
    Map<String, dynamic>? details,
  }) async {
    final profile = await getCurrentCityAuthorityProfile();

    await _firestore.collection('activity_logs').add({
      'action': action,
      'actorId': profile.uid,
      'actorName': profile.name ?? 'City Authority',
      'actorRole': 'city_authority',
      'city': profile.city,
      'state': profile.state,
      'issueId': issueId,
      'details': details ?? <String, dynamic>{},
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
