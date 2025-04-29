// lib/main.dart
// Fixed file with correct initialization order for Firebase Storage services

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:marinette/app/core/theme/app_theme.dart';
import 'package:marinette/app/data/services/background_music_handler.dart';
import 'package:marinette/app/data/services/content_service.dart';
import 'package:marinette/app/data/services/localization_service.dart' as ls;
import 'package:marinette/app/data/services/result_saver_service.dart';
import 'package:marinette/app/data/services/auth_service.dart';
import 'package:marinette/app/core/theme/theme_service.dart';
import 'package:marinette/app/data/services/user_preferences_service.dart';
import 'package:marinette/app/routes/app_routes.dart';
import 'package:marinette/app/data/services/storage_service.dart';
import 'package:marinette/app/data/services/storage_migration_service.dart';
import 'package:marinette/config/translations/app_translations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/data/services/stories_service.dart';
import 'firebase_options.dart';

void main() async {
  try {
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Hive first
    await Hive.initFlutter();
    debugPrint('Hive initialized');

    // Initialize SharedPreferences next
    await SharedPreferences.getInstance();
    debugPrint('SharedPreferences initialized');

    // Initialize Firebase Core BEFORE any Firebase services
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
    }

    // Load translations
    await Messages.loadTranslations();

    // Initialize all services in the correct order
    await _initializeServices();

    runApp(const MainApp());
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

Future<void> _initializeServices() async {
  // 1. Initialize basic services first
  await Get.putAsync(() => UserPreferencesService().init());
  debugPrint('UserPreferences service initialized');

  await Get.putAsync(() => ThemeService().init());
  debugPrint('Theme service initialized');

  // 2. Initialize Firebase-dependent services
  // Initialize Firebase Storage first since other services depend on it
  await Get.putAsync(() => StorageService().init(), permanent: true);
  debugPrint('Storage service initialized');

  // Now we can initialize Firebase-dependent services
  Get.put(StorageMigrationService(), permanent: true);
  debugPrint('Storage Migration service initialized');

  Get.put(AuthService());
  debugPrint('Auth service initialized');

  // 3. Initialize remaining services
  await Get.putAsync(() => ls.LocalizationService().init());
  debugPrint('Localization service initialized');

  await Get.putAsync(() => ContentService().init());
  debugPrint('Content service initialized');

  Get.put(StoriesService(), permanent: true);
  debugPrint('Stories service initialized');

  await Get.putAsync(() => ResultSaverService().init());
  debugPrint('ResultSaver service initialized');

  await BackgroundMusicHandler.instance.init();
  debugPrint('Background music handler initialized');
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    final localizationService = Get.find<ls.LocalizationService>();

    return GetMaterialApp(
      title: 'Marinette',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.getThemeMode(),
      translations: Messages(),
      locale: localizationService.getCurrentLocale(),
      fallbackLocale: const Locale('uk'),
      supportedLocales: ls.LocalizationService.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.HOME,
      getPages: AppRoutes.routes,
    );
  }
}