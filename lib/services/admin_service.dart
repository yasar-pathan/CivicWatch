import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:civic_watch/models/user_model.dart';
import 'package:civic_watch/utils/location_normalizer.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Fetch System Stats
  Future<Map<String, dynamic>> fetchAdminDashboardStats() async {
    try {
      // Avoid composite-index dependencies by reading once and aggregating client-side.
      final usersSnapshot = await _firestore.collection('users').get();
      final issuesSnapshot = await _firestore.collection('issues').get();

      int totalStateAuthorities = 0;
      int pendingRequests = 0;
      int activeState = 0;
      int totalCityAuthorities = 0;
      int totalIssues = 0;
      int escalatedIssues = 0;

      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        final role = (data['role'] ?? '').toString();
        final status = (data['status'] ?? '').toString();

        if (role == 'state_authority') {
          totalStateAuthorities++;
          if (status == 'pending_approval') pendingRequests++;
          if (status == 'approved') activeState++;
        }

        if (role == 'city_authority') {
          totalCityAuthorities++;
        }
      }

      for (final doc in issuesSnapshot.docs) {
        final data = doc.data();
        totalIssues++;
        if ((data['status'] ?? '').toString() == 'escalated') {
          escalatedIssues++;
        }
      }

      return {
        'totalStateAuthorities': totalStateAuthorities,
        'pendingRequests': pendingRequests,
        'activeState': activeState,
        'totalCityAuthorities': totalCityAuthorities,
        'totalIssues': totalIssues,
        'escalatedIssues': escalatedIssues,
      };
    } catch (e) {
      print('Error fetching stats: $e');
      return {};
    }
  }

  // 2. Fetch Pending Requests
  Stream<List<UserModel>> getPendingStateAuthRequests() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'state_authority')
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

  Future<void> createStateAuthorityAccount({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String state,
    required String governmentId,
    required String department,
    required String officeAddress,
    String? idProofUrl,
    String? authLetterUrl,
    bool emailSent = false,
    bool smsSent = false,
  }) async {
    FirebaseApp? tempApp;
    try {
      // Check if this email already exists in users collection.
      final existing = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw Exception('A user with this email already exists.');
      }

      // Create auth user with secondary app so current admin session is not replaced.
      final appName = 'admin_create_${DateTime.now().millisecondsSinceEpoch}';
      tempApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final newUid = credential.user!.uid;

      await _firestore.collection('users').doc(newUid).set({
        'uid': newUid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'state_authority',
        'status': 'approved',
        'isActive': true,
        'state': state,
        'governmentId': governmentId,
        'department': department,
        'officeAddress': officeAddress,
        'idProofUrl': idProofUrl,
        'authLetterUrl': authLetterUrl,
        'totalLogins': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': _auth.currentUser?.uid,
        'createdBy': _auth.currentUser?.uid,
      });

      await logActivity(
        action: 'created_sa',
        targetUserId: newUid,
        targetUserName: name,
        targetUserRole: 'state_authority',
        targetUserState: state,
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

  // 3. Approve State Authority
  Future<void> approveStateAuthority(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': _auth.currentUser?.uid,
    });

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};
    await logActivity(
      action: 'approved_state_authority',
      targetUserId: userId,
      targetUserName: userData['name']?.toString(),
      targetUserRole: userData['role']?.toString(),
      targetUserState: userData['state']?.toString(),
    );
  }

  // 4. Reject Registration
  Future<void> rejectRegistration(String userId, String reason) async {
    await _firestore.collection('users').doc(userId).update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedBy': _auth.currentUser?.uid,
      'rejectionReason': reason,
    });

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};
    await logActivity(
      action: 'rejected_registration',
      targetUserId: userId,
      targetUserName: userData['name']?.toString(),
      targetUserRole: userData['role']?.toString(),
      targetUserState: userData['state']?.toString(),
      details: {'reason': reason},
    );
  }

  // 5. Fetch All State Authorities
  Stream<List<UserModel>> getAllStateAuthorities() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'state_authority')
        .snapshots()
        .map((snapshot) {
          final users = snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList();
          users.sort((a, b) =>
              (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));
          return users;
        });
  }

  // 6. Log Activity
  Future<void> logActivity({
    required String action,
    String? targetUserId,
    String? targetUserName,
    String? targetUserRole,
    String? targetUserState,
    Map<String, dynamic>? details,
  }) async {
    await _firestore.collection('activity_logs').add({
      'action': action,
      'adminId': _auth.currentUser?.uid,
      'adminName': 'Admin',
      'timestamp': FieldValue.serverTimestamp(),
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'targetUserRole': targetUserRole,
      'targetUserState': targetUserState,
      'details': details ?? <String, dynamic>{},
    });
  }

  // 7. Deactivate User
  Future<void> deactivateUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': false,
      'deactivatedAt': FieldValue.serverTimestamp(),
      'deactivatedBy': _auth.currentUser?.uid,
    });
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};
    await logActivity(
      action: 'deactivated',
      targetUserId: userId,
      targetUserName: userData['name']?.toString(),
      targetUserRole: userData['role']?.toString(),
      targetUserState: userData['state']?.toString(),
    );
  }

  // 8. Activate User
  Future<void> activateUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': true,
      'deactivatedAt': null, // Clear deactivation timestamp or keep history differently
      'reactivatedAt': FieldValue.serverTimestamp(),
      'reactivatedBy': _auth.currentUser?.uid,
    });
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};
    await logActivity(
      action: 'activated',
      targetUserId: userId,
      targetUserName: userData['name']?.toString(),
      targetUserRole: userData['role']?.toString(),
      targetUserState: userData['state']?.toString(),
    );
  }

  Future<void> updateStateAuthority(
    String userId, {
    required String name,
    required String email,
    required String phone,
    required String state,
    required String governmentId,
    required String department,
    required String officeAddress,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'name': name,
      'email': email,
      'phone': phone,
      'state': state,
      'governmentId': governmentId,
      'department': department,
      'officeAddress': officeAddress,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await logActivity(
      action: 'edited_sa',
      targetUserId: userId,
      targetUserName: name,
      targetUserRole: 'state_authority',
      targetUserState: state,
    );
  }

  Future<void> markPasswordReset(String userId, {required String method}) async {
    await _firestore.collection('users').doc(userId).update({
      'passwordResetAt': FieldValue.serverTimestamp(),
      'passwordResetBy': _auth.currentUser?.uid,
    });

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};
    await logActivity(
      action: 'reset_password',
      targetUserId: userId,
      targetUserName: userData['name']?.toString(),
      targetUserRole: userData['role']?.toString(),
      targetUserState: userData['state']?.toString(),
      details: {'passwordMethod': method},
    );
  }

  Future<void> deleteStateAuthorityData(String userId, {required String reason}) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};
    await _firestore.collection('users').doc(userId).delete();

    await logActivity(
      action: 'deleted',
      targetUserId: userId,
      targetUserName: userData['name']?.toString(),
      targetUserRole: userData['role']?.toString(),
      targetUserState: userData['state']?.toString(),
      details: {'reason': reason},
    );
  }

  Stream<List<Map<String, dynamic>>> getActivityLogs({int limit = 50}) {
    return _firestore
        .collection('activity_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  Future<Map<String, dynamic>> fetchSystemAnalytics() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final issuesSnapshot = await _firestore.collection('issues').get();

    int citizens = 0;
    int cityAuthorities = 0;
    int stateAuthorities = 0;
    int admins = 0;
    int resolved = 0;
    int inProgress = 0;
    int pending = 0;
    int escalated = 0;

    for (final d in usersSnapshot.docs) {
      final role = (d.data()['role'] ?? '').toString();
      if (role == 'citizen') citizens++;
      if (role == 'city_authority') cityAuthorities++;
      if (role == 'state_authority') stateAuthorities++;
      if (role == 'admin') admins++;
    }

    for (final d in issuesSnapshot.docs) {
      final status = (d.data()['status'] ?? '').toString().toLowerCase();
      final isEscalated = d.data()['escalated'] == true || status == 'escalated';
      if (status == 'done' || status == 'resolved') resolved++;
      if (status == 'in_progress' || status == 'in work') inProgress++;
      if (status == 'pending' || status == 'reported' || status == 'recognized') pending++;
      if (isEscalated) escalated++;
    }

    return {
      'totalUsers': usersSnapshot.docs.length,
      'citizens': citizens,
      'cityAuthorities': cityAuthorities,
      'stateAuthorities': stateAuthorities,
      'admins': admins,
      'totalIssues': issuesSnapshot.docs.length,
      'resolvedIssues': resolved,
      'inProgressIssues': inProgress,
      'pendingIssues': pending,
      'escalatedIssues': escalated,
    };
  }

  Future<Map<String, int>> backfillCityNormalization() async {
    int usersUpdated = 0;
    int issuesUpdated = 0;

    final usersSnapshot = await _firestore.collection('users').get();
    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final rawCity = data['City'] ?? data['city'];
      final normalized = LocationNormalizer.normalize(rawCity?.toString());

      if (rawCity != null && normalized.isNotEmpty) {
        final currentNormalized = (data['cityNormalized'] ?? '').toString();
        final displayCity = LocationNormalizer.toTitleCase(rawCity.toString());

        if (currentNormalized != normalized ||
            (data['city'] ?? '').toString() != displayCity ||
            (data['City'] ?? '').toString() != displayCity) {
          await _firestore.collection('users').doc(doc.id).update({
            'cityNormalized': normalized,
            'city': displayCity,
            'City': displayCity,
          });
          usersUpdated++;
        }
      }
    }

    final issuesSnapshot = await _firestore.collection('issues').get();
    const batchLimit = 400;
    WriteBatch batch = _firestore.batch();
    int ops = 0;

    for (final doc in issuesSnapshot.docs) {
      final data = doc.data();
      final rawCity = data['City'] ?? data['city'];
      final normalized = LocationNormalizer.normalize(rawCity?.toString());

      if (rawCity != null && normalized.isNotEmpty) {
        final currentNormalized = (data['cityNormalized'] ?? '').toString();
        final displayCity = LocationNormalizer.toTitleCase(rawCity.toString());

        if (currentNormalized != normalized ||
            (data['City'] ?? '').toString() != displayCity) {
          batch.update(doc.reference, {
            'cityNormalized': normalized,
            'City': displayCity,
          });
          ops++;
          issuesUpdated++;

          if (ops >= batchLimit) {
            await batch.commit();
            batch = _firestore.batch();
            ops = 0;
          }
        }
      }
    }

    if (ops > 0) {
      await batch.commit();
    }

    await logActivity(
      action: 'city_normalization_backfill',
      targetUserId: _auth.currentUser?.uid,
      targetUserName: 'Admin',
      targetUserRole: 'admin',
      details: {
        'usersUpdated': usersUpdated,
        'issuesUpdated': issuesUpdated,
      },
    );

    return {
      'usersUpdated': usersUpdated,
      'issuesUpdated': issuesUpdated,
    };
  }
}
