// lib/main.dart
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
import 'package:marinette/app/data/services/firestore_analysis_service.dart';
import 'package:marinette/config/translations/app_translations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/data/services/stories_service.dart';
import 'firebase_options.dart';

// Add this function to check if it's the first launch
Future<bool> isFirstLaunch() async {
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('first_launch') ?? true;

  if (isFirstLaunch) {
    // Set first_launch to false for next time
    await prefs.setBool('first_launch', false);
    return true;
  }

  return false;
}

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
    debugPrint('Translations loaded');

    // Initialize services in the correct order
    await _initializeServices();

    // Check if this is the first launch
    final showAuthScreen = await isFirstLaunch();

    // Run the app with proper services already initialized
    runApp(MainApp(showAuthScreen: showAuthScreen));
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

Future<void> _initializeServices() async {
  // Initialize basic services first - sequence matters!
  await Get.putAsync(() => UserPreferencesService().init());
  debugPrint('UserPreferences service initialized');

  // Initialize theme service before auth service
  await Get.putAsync(() => ThemeService().init());
  debugPrint('Theme service initialized');

  // Initialize localization service before auth service
  await Get.putAsync(() => ls.LocalizationService().init());
  debugPrint('Localization service initialized');

  // Initialize Firebase Storage service
  await Get.putAsync(() => StorageService().init(), permanent: true);
  debugPrint('Storage service initialized');

  // Initialize Auth Service manually
  final authService = Get.put(AuthService());
  // Since the AuthService doesn't have an init() method, we need to rely on its onInit()
  // which is automatically called when the service is put in GetX
  debugPrint('Auth service initialized');

  // Initialize remaining services
  await Get.putAsync(() => FirestoreAnalysisService().init());
  debugPrint('FirestoreAnalysisService initialized');

  await Get.putAsync(() => ContentService().init());
  debugPrint('Content service initialized');

  Get.put(StoriesService(), permanent: true);
  debugPrint('Stories service initialized');

  await Get.putAsync(() => ResultSaverService().init());
  debugPrint('ResultSaver service initialized');

  // Initialize and start background music
  await BackgroundMusicHandler.instance.init();
  debugPrint('Background music handler initialized');
}

class MainApp extends StatelessWidget {
  final bool showAuthScreen;

  const MainApp({super.key, this.showAuthScreen = false});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    final localizationService = Get.find<ls.LocalizationService>();

    return GetMaterialApp(
      title: 'Beautymarine', // Updated app name
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.getThemeMode(),
      translations: Messages(),
      locale: Locale(localizationService.getCurrentLanguage() ?? 'uk'),
      fallbackLocale: const Locale('uk'),
      supportedLocales: ls.LocalizationService.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      initialRoute: showAuthScreen ? AppRoutes.AUTH : AppRoutes.HOME,
      getPages: AppRoutes.routes,
    );
  }
}