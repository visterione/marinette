// lib/app/data/services/user_activity_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:marinette/app/data/models/user_activity.dart';

class UserActivityService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add init method for proper GetX service initialization
  Future<UserActivityService> init() async {
    debugPrint('UserActivityService initialized');
    return this;
  }

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
        'timestamp': FieldValue.serverTimestamp(),
        'additionalData': additionalData,
      });

      debugPrint('Activity logged: $type - $description');
    } catch (e) {
      debugPrint('Error logging user activity: $e');
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
      debugPrint('Error getting user activities: $e');
      return [];
    }
  }

  // Get recent activities across all users (for admin use)
  Future<List<UserActivity>> getRecentActivities({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('user_activity')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => UserActivity.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('Error getting recent activities: $e');
      return [];
    }
  }

  // Get activity counts by type (for analytics)
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
      debugPrint('Error getting activity counts: $e');
      return {};
    }
  }

  // Get activity counts per day for a specific type (for charts)
  Future<Map<DateTime, int>> getActivityTimelineCounts(String type, {int days = 30}) async {
    try {
      // Get activities from the last N days
      final DateTime endDate = DateTime.now();
      final DateTime startDate = endDate.subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('user_activity')
          .where('type', isEqualTo: type)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      // Group by day
      Map<DateTime, int> countsByDay = {};
      for (var doc in snapshot.docs) {
        final timestamp = doc.data()['timestamp'] as Timestamp;
        final date = DateTime(
          timestamp.toDate().year,
          timestamp.toDate().month,
          timestamp.toDate().day,
        );

        countsByDay[date] = (countsByDay[date] ?? 0) + 1;
      }

      return countsByDay;
    } catch (e) {
      debugPrint('Error getting activity timeline counts: $e');
      return {};
    }
  }

  // Delete old activities (for maintenance)
  Future<int> deleteOldActivities({int olderThanDays = 90}) async {
    try {
      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));

      final snapshot = await _firestore
          .collection('user_activity')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      int count = 0;
      for (var doc in snapshot.docs) {
        await _firestore.collection('user_activity').doc(doc.id).delete();
        count++;
      }

      debugPrint('Deleted $count old activities');
      return count;
    } catch (e) {
      debugPrint('Error deleting old activities: $e');
      return 0;
    }
  }
}