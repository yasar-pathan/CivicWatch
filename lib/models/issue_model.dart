import 'package:cloud_firestore/cloud_firestore.dart';

class Issue {
  final String issueId;
  final String title;
  final String description;
  final String photoUrl;
  final String category;
  final String address;
  final double latitude;
  final double longitude;
  final String status;
  final int upvotes;
  final int commentCount;
  final String userId;
  final DateTime createdAt;

  Issue({
    required this.issueId,
    required this.title,
    required this.description,
    required this.photoUrl,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.upvotes,
    required this.commentCount,
    required this.userId,
    required this.createdAt,
  });

  factory Issue.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Handle Timestamp
    DateTime createdDate = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdDate = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        createdDate = DateTime.parse(data['createdAt']);
      }
    }

    return Issue(
      issueId: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      category: data['category'] ?? 'General',
      address: data['address'] ?? 'Unknown location',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Reported',
      upvotes: (data['upvotes'] ?? 0).toInt(),
      commentCount: (data['commentCount'] ?? 0).toInt(),
      userId: data['userId'] ?? '',
      createdAt: createdDate,
    );
  }
}
