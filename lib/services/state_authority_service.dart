import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:civic_watch/models/user_model.dart';
import 'package:civic_watch/utils/location_normalizer.dart';

class StateAuthorityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> getCurrentStateAuthorityProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) throw Exception('State authority profile not found');
    return doc.data()!;
  }

  Future<String> getCurrentState() async {
    final data = await getCurrentStateAuthorityProfile();
    return (data['state'] ?? '').toString();
  }

  Future<List<String>> getStateCities() async {
    final state = await getCurrentState();
    if (state.isEmpty) return [];

    final cityAuthorities = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'city_authority')
        .where('state', isEqualTo: state)
        .get();

    final cities = <String>{};
    for (final doc in cityAuthorities.docs) {
      final city = (doc.data()['city'] ?? '').toString();
      if (city.isNotEmpty) {
        cities.add(LocationNormalizer.toTitleCase(city));
      }
    }

    final sorted = cities.toList()..sort();
    return sorted;
  }

  Future<void> createCityAuthorityAccount({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String city,
    required String wardZone,
    required String governmentId,
    required String department,
    required String officeAddress,
    String? profilePhotoUrl,
    String? idProofUrl,
    String? authLetterUrl,
    bool emailSent = false,
    bool smsSent = false,
  }) async {
    FirebaseApp? tempApp;
    final state = await getCurrentState();
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final existing = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'city_authority')
          .where('state', isEqualTo: state)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw Exception('A city authority with this email already exists in your state.');
      }

      final existingEmployeeId = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'city_authority')
          .where('state', isEqualTo: state)
          .where('governmentId', isEqualTo: governmentId)
          .limit(1)
          .get();
      if (existingEmployeeId.docs.isNotEmpty) {
        throw Exception(
            'Government Employee ID already exists for a city authority in your state.');
      }

      final appName = 'state_create_${DateTime.now().millisecondsSinceEpoch}';
      tempApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final cityDisplay = LocationNormalizer.toTitleCase(city);
      final cityNormalized = LocationNormalizer.normalize(city);

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': normalizedEmail,
        'phone': phone,
        'role': 'city_authority',
        'status': 'approved',
        'isActive': true,
        'state': state,
        'city': cityDisplay,
        'City': cityDisplay,
        'cityNormalized': cityNormalized,
        'wardZone': wardZone,
        'governmentId': governmentId,
        'department': department,
        'officeAddress': officeAddress,
        'profilePhotoUrl': profilePhotoUrl,
        'idProofUrl': idProofUrl,
        'authLetterUrl': authLetterUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': _auth.currentUser?.uid,
        'totalLogins': 0,
      });

      await logActivity(
        action: 'created_ca',
        targetUserId: uid,
        targetUserName: name,
        targetUserRole: 'city_authority',
        targetUserCity: cityDisplay,
        details: {
          'employeeId': governmentId,
          'emailSent': emailSent,
          'smsSent': smsSent,
        },
      );
    } finally {
      if (tempApp != null) {
        try {
          await FirebaseAuth.instanceFor(app: tempApp).signOut();
        } catch (_) {}
        await tempApp.delete();
      }
    }
  }

  Stream<List<UserModel>> getCityAuthorities({
    String search = '',
    String filter = 'All',
  }) async* {
    final state = await getCurrentState();

    yield* _firestore
        .collection('users')
        .where('role', isEqualTo: 'city_authority')
        .where('state', isEqualTo: state)
        .snapshots()
        .map((snapshot) {
      var users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();

      if (filter == 'Active') {
        users = users.where((u) => u.isActive).toList();
      } else if (filter == 'Inactive') {
        users = users.where((u) => !u.isActive).toList();
      }

      final q = search.trim().toLowerCase();
      if (q.isNotEmpty) {
        users = users.where((u) {
          final name = (u.name ?? '').toLowerCase();
          final email = u.email.toLowerCase();
          final city = (u.city ?? '').toLowerCase();
          final employeeId = (u.governmentId ?? '').toLowerCase();
          return name.contains(q) ||
              email.contains(q) ||
              city.contains(q) ||
              employeeId.contains(q);
        }).toList();
      }

      users.sort((a, b) =>
          (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));
      return users;
    });
  }

  Stream<List<UserModel>> getPendingCityRequests() async* {
    final state = await getCurrentState();

    yield* _firestore
        .collection('users')
        .where('role', isEqualTo: 'city_authority')
        .where('state', isEqualTo: state)
        .snapshots()
        .map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .where((u) => u.status == 'pending_approval')
          .toList();

      users.sort((a, b) {
        final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
      return users;
    });
  }

  Future<void> approveCityAuthority(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': _auth.currentUser?.uid,
    });

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    await logActivity(
      action: 'approved_ca',
      targetUserId: uid,
      targetUserName: data['name']?.toString(),
      targetUserRole: 'city_authority',
      targetUserCity: data['city']?.toString(),
    );
  }

  Future<void> rejectCityAuthority(String uid, String reason) async {
    await _firestore.collection('users').doc(uid).update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedBy': _auth.currentUser?.uid,
      'rejectionReason': reason,
    });

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    await logActivity(
      action: 'rejected_ca',
      targetUserId: uid,
      targetUserName: data['name']?.toString(),
      targetUserRole: 'city_authority',
      targetUserCity: data['city']?.toString(),
      details: {'reason': reason},
    );
  }

  Future<void> updateCityAuthority(
    String uid, {
    required String name,
    required String email,
    required String phone,
    required String city,
    required String wardZone,
    required String governmentId,
    required String department,
    required String officeAddress,
  }) async {
    final cityDisplay = LocationNormalizer.toTitleCase(city);
    await _firestore.collection('users').doc(uid).update({
      'name': name,
      'email': email,
      'phone': phone,
      'city': cityDisplay,
      'City': cityDisplay,
      'cityNormalized': LocationNormalizer.normalize(city),
      'wardZone': wardZone,
      'governmentId': governmentId,
      'department': department,
      'officeAddress': officeAddress,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await logActivity(
      action: 'edited_ca',
      targetUserId: uid,
      targetUserName: name,
      targetUserRole: 'city_authority',
      targetUserCity: cityDisplay,
    );
  }

  Future<void> deactivateCityAuthority(String uid, {String? reason}) async {
    await _firestore.collection('users').doc(uid).update({
      'isActive': false,
      'deactivatedAt': FieldValue.serverTimestamp(),
      'deactivatedBy': _auth.currentUser?.uid,
      'deactivationReason': reason,
    });

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    await logActivity(
      action: 'deactivated_ca',
      targetUserId: uid,
      targetUserName: data['name']?.toString(),
      targetUserRole: 'city_authority',
      targetUserCity: data['city']?.toString(),
      details: {'reason': reason},
    );
  }

  Future<void> activateCityAuthority(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isActive': true,
      'reactivatedAt': FieldValue.serverTimestamp(),
      'reactivatedBy': _auth.currentUser?.uid,
    });

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    await logActivity(
      action: 'activated_ca',
      targetUserId: uid,
      targetUserName: data['name']?.toString(),
      targetUserRole: 'city_authority',
      targetUserCity: data['city']?.toString(),
    );
  }

  Future<void> deleteCityAuthorityFirestoreOnly(String uid,
      {required String reason}) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    await _firestore.collection('users').doc(uid).delete();

    await logActivity(
      action: 'deleted_ca',
      targetUserId: uid,
      targetUserName: data['name']?.toString(),
      targetUserRole: 'city_authority',
      targetUserCity: data['city']?.toString(),
      details: {'reason': reason, 'authDeleted': false},
    );
  }

  Stream<List<Map<String, dynamic>>> getIssues({
    required bool escalated,
    String selectedCity = 'All',
    String statusFilter = 'All',
    String categoryFilter = 'All',
    String query = '',
  }) async* {
    final state = await getCurrentState();
    final stateCities = (await getStateCities()).toSet();

    yield* _firestore.collection('issues').snapshots().map((snapshot) {
      final docs = snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();

      var filtered = docs.where((issue) {
        final issueState =
            LocationNormalizer.toTitleCase((issue['state'] ?? '').toString());
        final issueCity = LocationNormalizer.toTitleCase(
            (issue['City'] ?? issue['city'] ?? '').toString());
        final issueEscalated = issue['escalated'] == true ||
            (issue['status'] ?? '').toString().toLowerCase() == 'escalated';

        final stateMatch = issueState.isNotEmpty
            ? issueState == LocationNormalizer.toTitleCase(state)
            : stateCities.contains(issueCity);
        final escalatedMatch = issueEscalated == escalated;
        final cityMatch = selectedCity == 'All' || issueCity == selectedCity;

        final status = (issue['status'] ?? '').toString();
        final statusMatch = statusFilter == 'All' || status == statusFilter;

        final category = (issue['category'] ?? '').toString();
        final categoryMatch = categoryFilter == 'All' || category == categoryFilter;

        final q = query.trim().toLowerCase();
        final queryMatch = q.isEmpty ||
            (issue['title'] ?? '').toString().toLowerCase().contains(q) ||
            (issue['description'] ?? '').toString().toLowerCase().contains(q) ||
            issueCity.toLowerCase().contains(q) ||
            (issue['id'] ?? '').toString().toLowerCase().contains(q);

        return stateMatch &&
            escalatedMatch &&
            cityMatch &&
            statusMatch &&
            categoryMatch &&
            queryMatch;
      }).toList();

      filtered.sort((a, b) {
        final at = a['createdAt'] as Timestamp?;
        final bt = b['createdAt'] as Timestamp?;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });

      return filtered;
    });
  }

  Future<void> addEscalatedIssueComment({
    required String issueId,
    required String comment,
    bool pushReminder = false,
    bool markCritical = false,
  }) async {
    await _firestore
        .collection('issues')
        .doc(issueId)
        .collection('state_actions')
        .add({
      'comment': comment,
      'pushReminder': pushReminder,
      'markCritical': markCritical,
      'by': _auth.currentUser?.uid,
      'byRole': 'state_authority',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (markCritical) {
      await _firestore.collection('issues').doc(issueId).update({
        'critical': true,
        'criticalAt': FieldValue.serverTimestamp(),
      });
    }

    await logActivity(
      action: 'commented_escalated_issue',
      targetUserId: issueId,
      targetUserRole: 'issue',
      details: {
        'pushReminder': pushReminder,
        'markCritical': markCritical,
      },
    );
  }

  Future<Map<String, dynamic>> getStateDashboardStats() async {
    final state = await getCurrentState();
    final issues = await _firestore.collection('issues').get();

    final cityAuthoritiesSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'city_authority')
        .where('state', isEqualTo: state)
        .get();
    final cityAuthorities = cityAuthoritiesSnapshot.docs;

    final pendingCityRequests = cityAuthorities
        .where((d) => (d.data()['status'] ?? '') == 'pending_approval')
        .length;

    final activeCityAuthorities =
        cityAuthorities.where((d) => d.data()['isActive'] != false).length;

    final scopedIssues = issues.docs.where((d) {
      final data = d.data();
      if ((data['state'] ?? '').toString().isNotEmpty) {
        return data['state'] == state;
      }
      // Backward compatibility when state is not stored yet.
      final city = LocationNormalizer.toTitleCase(
          (data['City'] ?? data['city'] ?? '').toString());
      return cityAuthorities
          .any((u) => LocationNormalizer.toTitleCase((u.data()['city'] ?? '').toString()) == city);
    }).toList();

    int escalated = 0;
    int nonEscalated = 0;
    int resolvedThisMonth = 0;

    final now = DateTime.now();
    for (final d in scopedIssues) {
      final data = d.data();
      final isEscalated = data['escalated'] == true ||
          (data['status'] ?? '').toString().toLowerCase() == 'escalated';
      if (isEscalated) {
        escalated++;
      } else {
        nonEscalated++;
      }

      final status = (data['status'] ?? '').toString().toLowerCase();
      final updated = data['updatedAt'] as Timestamp?;
      if ((status == 'done' || status == 'resolved') && updated != null) {
        final dt = updated.toDate();
        if (dt.year == now.year && dt.month == now.month) {
          resolvedThisMonth++;
        }
      }
    }

    return {
      'totalCityAuthorities': cityAuthorities.length,
      'activeCityAuthorities': activeCityAuthorities,
      'pendingCityRequests': pendingCityRequests,
      'totalIssues': scopedIssues.length,
      'nonEscalatedIssues': nonEscalated,
      'escalatedIssues': escalated,
      'resolvedThisMonth': resolvedThisMonth,
      'state': state,
    };
  }

  Future<Map<String, dynamic>> getStateAnalytics() async {
    final stats = await getStateDashboardStats();
    final state = stats['state'] as String;

    final issues = await _firestore.collection('issues').get();

    final cityAuthoritiesSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'city_authority')
        .where('state', isEqualTo: state)
        .get();
    final cityAuthorities = cityAuthoritiesSnapshot.docs;

    final citySet = cityAuthorities
        .map((d) => LocationNormalizer.toTitleCase((d.data()['city'] ?? '').toString()))
        .toSet();

    final scopedIssues = issues.docs.where((d) {
      final data = d.data();
      if ((data['state'] ?? '').toString().isNotEmpty) {
        return data['state'] == state;
      }
      final city = LocationNormalizer.toTitleCase(
          (data['City'] ?? data['city'] ?? '').toString());
      return citySet.contains(city);
    }).toList();

    int reported = 0;
    int recognized = 0;
    int inWork = 0;
    int done = 0;
    int escalated = 0;
    final byCity = <String, Map<String, int>>{};

    for (final issue in scopedIssues) {
      final data = issue.data();
      final status = (data['status'] ?? '').toString();
      final city = LocationNormalizer.toTitleCase(
          (data['City'] ?? data['city'] ?? '').toString());

      byCity.putIfAbsent(city, () => {
            'total': 0,
            'resolved': 0,
            'pending': 0,
            'escalated': 0,
          });
      byCity[city]!['total'] = (byCity[city]!['total'] ?? 0) + 1;

      if (status == 'Reported') reported++;
      if (status == 'Recognized') recognized++;
      if (status == 'In Work') inWork++;
      if (status == 'Done' || status == 'Resolved') {
        done++;
        byCity[city]!['resolved'] = (byCity[city]!['resolved'] ?? 0) + 1;
      } else {
        byCity[city]!['pending'] = (byCity[city]!['pending'] ?? 0) + 1;
      }

      final isEscalated = data['escalated'] == true ||
          status.toLowerCase() == 'escalated';
      if (isEscalated) {
        escalated++;
        byCity[city]!['escalated'] = (byCity[city]!['escalated'] ?? 0) + 1;
      }
    }

    return {
      'state': state,
      'totalIssues': scopedIssues.length,
      'reported': reported,
      'recognized': recognized,
      'inWork': inWork,
      'done': done,
      'escalated': escalated,
      'byCity': byCity,
    };
  }

  Stream<List<Map<String, dynamic>>> getStateActivityLogs({int limit = 100}) {
    return _firestore
        .collection('activity_logs')
        .where('adminId', isEqualTo: _auth.currentUser?.uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();
      list.sort((a, b) {
        final at = a['timestamp'] as Timestamp?;
        final bt = b['timestamp'] as Timestamp?;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
      return list.take(limit).toList();
    });
  }

  Future<void> logActivity({
    required String action,
    String? targetUserId,
    String? targetUserName,
    String? targetUserRole,
    String? targetUserCity,
    Map<String, dynamic>? details,
  }) async {
    await _firestore.collection('activity_logs').add({
      'action': action,
      'adminId': _auth.currentUser?.uid,
      'adminName': 'State Authority',
      'timestamp': FieldValue.serverTimestamp(),
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'targetUserRole': targetUserRole,
      'targetUserCity': targetUserCity,
      'details': details ?? <String, dynamic>{},
    });
  }
}
