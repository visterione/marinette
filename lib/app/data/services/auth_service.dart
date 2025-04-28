// lib/app/data/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marinette/app/data/models/user_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rxn<User> _firebaseUser = Rxn<User>();
  final Rxn<UserModel> _userModel = Rxn<UserModel>();
  final RxBool isLoading = false.obs;

  User? get currentUser => _firebaseUser.value;
  UserModel? get userModel => _userModel.value;
  Stream<User?> get userStream => _auth.authStateChanges();
  bool get isLoggedIn => _firebaseUser.value != null;

  @override
  void onInit() {
    super.onInit();
    _firebaseUser.bindStream(_auth.authStateChanges());
    ever(_firebaseUser, _setInitialScreen);
  }

  void _setInitialScreen(User? user) async {
    if (user != null) {
      // Користувач увійшов в систему, отримуємо дані з Firestore
      await _getUserData();
    } else {
      // Користувач не увійшов в систему
      _userModel.value = null;
    }
  }

  // Реєстрація нового користувача
  Future<bool> registerWithEmailAndPassword(String email, String password) async {
    try {
      isLoading.value = true;
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

      // Створення запису в Firestore
      final user = result.user;
      if (user != null) {
        final userData = UserModel(
          uid: user.uid,
          email: user.email!,
          displayName: user.displayName,
          photoUrl: user.photoURL,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(userData.toMap());
        _userModel.value = userData;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Помилка реєстрації: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Вхід користувача
  Future<bool> loginWithEmailAndPassword(String email, String password) async {
    try {
      isLoading.value = true;
      final UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      // Оновлення дати останнього входу
      final user = result.user;
      if (user != null) {
        try {
          await _firestore.collection('users').doc(user.uid).update({
            'lastLogin': DateTime.now().millisecondsSinceEpoch
          });
        } catch (e) {
          // Якщо документ не існує, створіть його
          final newUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            photoUrl: user.photoURL,
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );
          await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        }

        await _getUserData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Помилка входу: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Отримання даних користувача з Firestore
  Future<void> _getUserData() async {
    try {
      if (_firebaseUser.value != null) {
        // Спочатку перевіримо чи існує документ
        final docRef = _firestore.collection('users').doc(_firebaseUser.value!.uid);
        final docSnapshot = await docRef.get();

        if (docSnapshot.exists) {
          // Документ існує
          final data = docSnapshot.data();
          if (data != null) {
            _userModel.value = UserModel.fromMap(data);
          }
        } else {
          // Документ не існує - створюємо новий
          final newUser = UserModel(
            uid: _firebaseUser.value!.uid,
            email: _firebaseUser.value!.email ?? '',
            displayName: _firebaseUser.value!.displayName,
            photoUrl: _firebaseUser.value!.photoURL,
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );

          // Створюємо новий документ
          await docRef.set(newUser.toMap());
          _userModel.value = newUser;
        }
      }
    } catch (e) {
      debugPrint('Помилка отримання даних користувача: $e');
    }
  }

  // Оновлення профілю користувача
  Future<bool> updateUserProfile({
    String? displayName,
    String? photoUrl,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      if (_firebaseUser.value == null) return false;

      final updates = <String, dynamic>{};

      if (displayName != null) {
        updates['displayName'] = displayName;
      }

      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
      }

      if (preferences != null) {
        updates['preferences'] = preferences;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(_firebaseUser.value!.uid).update(updates);
        await _getUserData(); // Оновлюємо локальні дані
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Помилка оновлення профілю: $e');
      return false;
    }
  }

  // Вихід з системи
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userModel.value = null;
    } catch (e) {
      debugPrint('Помилка виходу з системи: $e');
    }
  }

  // Скидання паролю
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      debugPrint('Помилка скидання паролю: $e');
      return false;
    }
  }
}