import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin', 'state_authority', 'city_authority', 'citizen'
  final String status; // 'approved', 'pending_approval', 'rejected'
  final bool isActive;
  final String? name;
  final String? phone;
  final String? state;
  final String? city;
  final String? governmentId;
  final String? department;
  final String? officeAddress;
  final String? profilePhotoUrl;
  final String? idProofUrl;
  final String? authLetterUrl;
  final String? fcmToken;
  final String? createdBy;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final String? deactivatedBy;
  final DateTime? deactivatedAt;
  final String? deactivationReason;
  final String? reactivatedBy;
  final DateTime? reactivatedAt;
  final String? passwordResetBy;
  final DateTime? passwordResetAt;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final int totalLogins;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.status = 'approved', // default for citizen
    this.isActive = true,
    this.name,
    this.phone,
    this.state,
    this.city,
    this.governmentId,
    this.department,
    this.officeAddress,
    this.profilePhotoUrl,
    this.idProofUrl,
    this.authLetterUrl,
    this.fcmToken,
    this.createdBy,
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionReason,
    this.deactivatedBy,
    this.deactivatedAt,
    this.deactivationReason,
    this.reactivatedBy,
    this.reactivatedAt,
    this.passwordResetBy,
    this.passwordResetAt,
    this.createdAt,
    this.lastLoginAt,
    this.totalLogins = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      role: data['role'] ?? 'citizen',
      status: data['status'] ?? 'approved',
      isActive: data['isActive'] ?? true,
      name: data['name'],
      phone: data['phone'],
      state: data['state'],
      city: data['city'],
      governmentId: data['governmentId'],
      department: data['department'],
      officeAddress: data['officeAddress'],
      profilePhotoUrl: data['profilePhotoUrl'],
      idProofUrl: data['idProofUrl'],
      authLetterUrl: data['authLetterUrl'],
      fcmToken: data['fcmToken'],
      createdBy: data['createdBy'],
      approvedBy: data['approvedBy'],
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectedBy: data['rejectedBy'],
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
      deactivatedBy: data['deactivatedBy'],
      deactivatedAt: (data['deactivatedAt'] as Timestamp?)?.toDate(),
      deactivationReason: data['deactivationReason'],
      reactivatedBy: data['reactivatedBy'],
      reactivatedAt: (data['reactivatedAt'] as Timestamp?)?.toDate(),
      passwordResetBy: data['passwordResetBy'],
      passwordResetAt: (data['passwordResetAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      totalLogins: (data['totalLogins'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'status': status,
      'isActive': isActive,
      'name': name,
      'phone': phone,
      'state': state,
      'city': city,
      'governmentId': governmentId,
      'department': department,
      'officeAddress': officeAddress,
      'profilePhotoUrl': profilePhotoUrl,
      'idProofUrl': idProofUrl,
      'authLetterUrl': authLetterUrl,
      'fcmToken': fcmToken,
      'createdBy': createdBy,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt,
      'rejectedBy': rejectedBy,
      'rejectedAt': rejectedAt,
      'rejectionReason': rejectionReason,
      'deactivatedBy': deactivatedBy,
      'deactivatedAt': deactivatedAt,
      'deactivationReason': deactivationReason,
      'reactivatedBy': reactivatedBy,
      'reactivatedAt': reactivatedAt,
      'passwordResetBy': passwordResetBy,
      'passwordResetAt': passwordResetAt,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
      'totalLogins': totalLogins,
    };
  }
}
