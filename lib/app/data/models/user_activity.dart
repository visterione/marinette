// lib/app/data/models/user_activity.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserActivity {
  final String id;
  final String userId;
  final String type; // login, analysis, article_view, etc.
  final String description;
  final Timestamp timestamp;
  final Map<String, dynamic>? additionalData;

  UserActivity({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.timestamp,
    this.additionalData,
  });

  factory UserActivity.fromMap(Map<String, dynamic> map, String id) {
    return UserActivity(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      additionalData: map['additionalData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'description': description,
      'timestamp': timestamp,
      'additionalData': additionalData,
    };
  }
}

// User Activity Service to log user activities
class UserActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Log a user activity
  Future<void> logActivity({
    required String userId,
    required String type,
    required String description,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _firestore.collection('user_activity').add({
        'userId': userId,
        'type': type,
        'description': description,
        'timestamp': Timestamp.now(),
        'additionalData': additionalData,
      });
    } catch (e) {
      print('Error logging user activity: $e');
    }
  }

  // Get activities for a specific user
  Future<List<UserActivity>> getUserActivities(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('user_activity')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => UserActivity.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error getting user activities: $e');
      return [];
    }
  }

  // Get recent activities across all users
  Future<List<UserActivity>> getRecentActivities({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('user_activity')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => UserActivity.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error getting recent activities: $e');
      return [];
    }
  }

  // Get activity counts by type
  Future<Map<String, int>> getActivityCountsByType() async {
    try {
      final snapshot = await _firestore
          .collection('user_activity')
          .get();

      Map<String, int> countsByType = {};
      for (var doc in snapshot.docs) {
        final type = doc.data()['type'] as String;
        countsByType[type] = (countsByType[type] ?? 0) + 1;
      }

      return countsByType;
    } catch (e) {
      print('Error getting activity counts: $e');
      return {};
    }
  }
}