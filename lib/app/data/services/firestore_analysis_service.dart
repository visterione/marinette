// lib/app/data/services/firestore_analysis_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/face_analysis_result.dart';
import 'package:marinette/app/data/services/auth_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart' as path;

class FirestoreAnalysisService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _authService = Get.find<AuthService>();

  static const String analysisCollection = 'user_analysis';
  static const String analysisFolderPath = 'analysis_images';

  Future<FirestoreAnalysisService> init() async {
    debugPrint('FirestoreAnalysisService initialized');
    return this;
  }

  /// Saves analysis result to Firestore and uploads the image to Firebase Storage
  Future<Map<String, dynamic>?> saveAnalysisResult({
    required String imagePath,
    required FaceAnalysisResult result,
  }) async {
    try {
      // Check if user is logged in
      if (_authService.currentUser == null) {
        debugPrint('User not logged in, cannot save to Firestore');
        return null;
      }

      final userId = _authService.currentUser!.uid;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = path.basename(imagePath);
      final storageRef = _storage.ref()
          .child(analysisFolderPath)
          .child(userId)
          .child('${timestamp}_$fileName');

      // Upload image to Firebase Storage
      final File imageFile = File(imagePath);
      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Prepare data for Firestore
      final resultData = {
        'userId': userId,
        'imagePath': downloadUrl,
        'faceShape': result.faceShape,
        'colorType': result.colorType,
        'makeupRecommendations': result.makeupRecommendations,
        'hairstyleRecommendations': result.hairstyleRecommendations,
        'skincareRecommendations': result.skincareRecommendations,
        'timestamp': timestamp,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      final docRef = await _firestore.collection(analysisCollection).add(resultData);

      // Update result data with document ID
      resultData['id'] = docRef.id;
      resultData['localImagePath'] = imagePath;

      debugPrint('Analysis result saved to Firestore successfully: ${docRef.id}');
      return resultData;
    } catch (e) {
      debugPrint('Error saving analysis result to Firestore: $e');
      return null;
    }
  }

  /// Get all analysis results for the current user
  Future<List<Map<String, dynamic>>> getUserAnalysisResults() async {
    try {
      // Check if user is logged in
      if (_authService.currentUser == null) {
        debugPrint('User not logged in, cannot fetch from Firestore');
        return [];
      }

      final userId = _authService.currentUser!.uid;
      final snapshot = await _firestore
          .collection(analysisCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      final results = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      debugPrint('Fetched ${results.length} analysis results from Firestore');
      return results;
    } catch (e) {
      debugPrint('Error fetching analysis results from Firestore: $e');
      return [];
    }
  }

  /// Delete an analysis result from Firestore and Storage
  Future<bool> deleteAnalysisResult(String docId, String imageUrl) async {
    try {
      // Check if user is logged in
      if (_authService.currentUser == null) {
        debugPrint('User not logged in, cannot delete from Firestore');
        return false;
      }

      // Delete document from Firestore
      await _firestore.collection(analysisCollection).doc(docId).delete();

      // Delete image from Storage if it's a Firebase Storage URL
      if (imageUrl.contains('firebasestorage.googleapis.com')) {
        try {
          // Extract reference from URL
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
          debugPrint('Image deleted from Firebase Storage: $imageUrl');
        } catch (e) {
          debugPrint('Error deleting image from Firebase Storage: $e');
          // Continue anyway as the document is already deleted
        }
      }

      debugPrint('Analysis result deleted from Firestore: $docId');
      return true;
    } catch (e) {
      debugPrint('Error deleting analysis result from Firestore: $e');
      return false;
    }
  }

  /// Sync local analysis results to Firestore
  Future<int> syncLocalResultsToFirestore(List<Map<String, dynamic>> localResults) async {
    try {
      // Check if user is logged in
      if (_authService.currentUser == null) {
        debugPrint('User not logged in, cannot sync to Firestore');
        return 0;
      }

      int syncedCount = 0;
      final userId = _authService.currentUser!.uid;

      for (var result in localResults) {
        try {
          // Check if result is already in Firestore
          final existingResults = await _firestore
              .collection(analysisCollection)
              .where('userId', isEqualTo: userId)
              .where('timestamp', isEqualTo: result['timestamp'])
              .get();

          if (existingResults.docs.isNotEmpty) {
            // Already synced, skip
            continue;
          }

          // Upload image to Firebase Storage
          final localImagePath = result['imagePath'];
          final timestamp = result['timestamp'];
          final fileName = path.basename(localImagePath);
          final storageRef = _storage.ref()
              .child(analysisFolderPath)
              .child(userId)
              .child('${timestamp}_$fileName');

          final File imageFile = File(localImagePath);
          if (await imageFile.exists()) {
            final uploadTask = await storageRef.putFile(imageFile);
            final downloadUrl = await uploadTask.ref.getDownloadURL();

            // Prepare data for Firestore
            final resultData = {
              'userId': userId,
              'imagePath': downloadUrl,
              'faceShape': result['faceShape'],
              'colorType': result['colorType'],
              'makeupRecommendations': List<String>.from(result['makeupRecommendations']),
              'hairstyleRecommendations': List<String>.from(result['hairstyleRecommendations']),
              'skincareRecommendations': List<String>.from(result['skincareRecommendations']),
              'timestamp': timestamp,
              'createdAt': FieldValue.serverTimestamp(),
              'syncedFromLocal': true,
            };

            // Save to Firestore
            await _firestore.collection(analysisCollection).add(resultData);
            syncedCount++;
          }
        } catch (e) {
          debugPrint('Error syncing local result to Firestore: $e');
          // Continue with next result
          continue;
        }
      }

      debugPrint('Synced $syncedCount local results to Firestore');
      return syncedCount;
    } catch (e) {
      debugPrint('Error syncing local results to Firestore: $e');
      return 0;
    }
  }

  /// Get count of user's analysis results in the cloud
  Future<int> getUserAnalysisResultsCount() async {
    try {
      // Check if user is logged in
      if (_authService.currentUser == null) {
        return 0;
      }

      final userId = _authService.currentUser!.uid;

      // Use the count() method only if available in your Firebase version
      // Otherwise, fetch all documents and count them locally
      try {
        final snapshot = await _firestore
            .collection(analysisCollection)
            .where('userId', isEqualTo: userId)
            .count()
            .get();

        return snapshot.count ?? 0; // Use null-safe access and provide default value
      } catch (e) {
        // Fallback to traditional count if count() method not available
        final snapshot = await _firestore
            .collection(analysisCollection)
            .where('userId', isEqualTo: userId)
            .get();

        return snapshot.docs.length;
      }
    } catch (e) {
      debugPrint('Error getting analysis results count: $e');
      return 0;
    }
  }
}