// lib/app/data/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:marinette/app/data/models/user_model.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:marinette/app/modules/profile/profile_screen.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final Rxn<User> _firebaseUser = Rxn<User>();
  final Rxn<UserModel> _userModel = Rxn<UserModel>();
  final RxBool isLoading = false.obs;
  final RxBool isGithubLoading = false.obs;

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

  // Авторизація через Google
  Future<bool> signInWithGoogle() async {
    try {
      isLoading.value = true;

      // Починаємо процес входу Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Користувач скасував вхід
        return false;
      }

      // Отримуємо дані аутентифікації
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Авторизуємося в Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Перевіряємо, чи існує користувач у Firestore
        final docRef = _firestore.collection('users').doc(user.uid);
        final docSnapshot = await docRef.get();

        if (!docSnapshot.exists) {
          // Створюємо новий документ для користувача
          final userData = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            photoUrl: user.photoURL,
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );

          await docRef.set(userData.toMap());
        } else {
          // Оновлюємо дату останнього входу
          await docRef.update({
            'lastLogin': DateTime.now().millisecondsSinceEpoch,
            'displayName': user.displayName,
            'photoUrl': user.photoURL,
          });
        }

        await _getUserData();

        // Переходимо на екран профілю
        Get.off(() => ProfileScreen());

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Помилка входу через Google: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Авторизація через GitHub
  Future<bool> signInWithGitHub() async {
    try {
      isGithubLoading.value = true;

      // Create GitHub provider
      final githubProvider = GithubAuthProvider();

      // Sign in with popup/redirect based on platform
      UserCredential userCredential;
      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(githubProvider);
      } else {
        userCredential = await _auth.signInWithProvider(githubProvider);
      }

      final User? user = userCredential.user;

      if (user != null) {
        // Перевіряємо, чи існує користувач у Firestore
        final docRef = _firestore.collection('users').doc(user.uid);
        final docSnapshot = await docRef.get();

        if (!docSnapshot.exists) {
          // Створюємо новий документ для користувача
          final userData = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            photoUrl: user.photoURL,
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );

          await docRef.set(userData.toMap());
        } else {
          // Оновлюємо дату останнього входу
          await docRef.update({
            'lastLogin': DateTime.now().millisecondsSinceEpoch,
            'displayName': user.displayName,
            'photoUrl': user.photoURL,
          });
        }

        await _getUserData();

        // Переходимо на екран профілю
        Get.off(() => ProfileScreen());

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Помилка входу через GitHub: $e');
      return false;
    } finally {
      isGithubLoading.value = false;
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
      await _googleSignIn.signOut();
      await _auth.signOut();
      _userModel.value = null;
    } catch (e) {
      debugPrint('Помилка виходу з системи: $e');
    }
  }
}