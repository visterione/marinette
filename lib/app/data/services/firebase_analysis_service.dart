// lib/app/data/services/firebase_analysis_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/face_analysis_result.dart';
import 'package:marinette/app/data/services/auth_service.dart';
import 'package:marinette/app/data/services/user_activity_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class FirebaseAnalysisService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = Get.find<AuthService>();
  final UserActivityService _activityService = Get.find<UserActivityService>();

  // Collection name for analysis results
  static const String _collectionName = 'user_analysis';

  Future<FirebaseAnalysisService> init() async {
    debugPrint('FirebaseAnalysisService initialized');
    return this;
  }

  // Save analysis result to Firebase
  Future<String?> saveAnalysisResult({
    required String imagePath,
    required FaceAnalysisResult result,
  }) async {
    try {
      // Check if user is logged in
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        debugPrint('Cannot save to Firebase: User not logged in');
        return null;
      }

      // Prepare data for Firestore
      final data = {
        'userId': currentUser.uid,
        'faceShape': result.faceShape,
        'colorType': result.colorType,
        'makeupRecommendations': result.makeupRecommendations,
        'hairstyleRecommendations': result.hairstyleRecommendations,
        'skincareRecommendations': result.skincareRecommendations,
        'createdAt': FieldValue.serverTimestamp(),
        'imagePathLocal': imagePath, // Store local path for reference
      };

      // Save to Firestore
      final docRef = await _firestore.collection(_collectionName).add(data);

      // Log activity
      await _activityService.logActivity(
        userId: currentUser.uid,
        type: 'analysis',
        description: 'Face analysis performed: ${result.faceShape} + ${result.colorType}',
        additionalData: {
          'faceShape': result.faceShape,
          'colorType': result.colorType,
          'analysisId': docRef.id,
        },
      );

      debugPrint('Analysis result saved to Firebase with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error saving analysis result to Firebase: $e');
      return null;
    }
  }

  // Get all analysis results for current user
  Future<List<Map<String, dynamic>>> getUserAnalysisResults() async {
    try {
      // Check if user is logged in
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        debugPrint('Cannot fetch from Firebase: User not logged in');
        return [];
      }

      // Query Firestore
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error fetching user analysis results: $e');
      return [];
    }
  }

  // Delete analysis result from Firebase
  Future<bool> deleteAnalysisResult(String analysisId) async {
    try {
      // Check if user is logged in
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        debugPrint('Cannot delete from Firebase: User not logged in');
        return false;
      }

      // Check if result belongs to current user
      final doc = await _firestore.collection(_collectionName).doc(analysisId).get();
      if (!doc.exists || doc.data()?['userId'] != currentUser.uid) {
        debugPrint('Cannot delete: Result does not exist or does not belong to current user');
        return false;
      }

      // Delete from Firestore
      await _firestore.collection(_collectionName).doc(analysisId).delete();

      debugPrint('Analysis result deleted from Firebase: $analysisId');
      return true;
    } catch (e) {
      debugPrint('Error deleting analysis result from Firebase: $e');
      return false;
    }
  }

  // Get a single analysis result
  Future<Map<String, dynamic>?> getAnalysisResult(String analysisId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(analysisId).get();
      if (!doc.exists) {
        return null;
      }

      return {
        'id': doc.id,
        ...doc.data()!,
      };
    } catch (e) {
      debugPrint('Error fetching analysis result: $e');
      return null;
    }
  }

  // Create FaceAnalysisResult from Firestore data
  FaceAnalysisResult? createResultFromFirestore(Map<String, dynamic> data) {
    try {
      return FaceAnalysisResult(
        faceShape: data['faceShape'] ?? '',
        colorType: data['colorType'] ?? '',
        makeupRecommendations: List<String>.from(data['makeupRecommendations'] ?? []),
        hairstyleRecommendations: List<String>.from(data['hairstyleRecommendations'] ?? []),
        skincareRecommendations: List<String>.from(data['skincareRecommendations'] ?? []),
      );
    } catch (e) {
      debugPrint('Error creating result from Firestore data: $e');
      return null;
    }
  }
}