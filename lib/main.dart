// lib/main.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:marinette/app/modules/home/home_screen.dart';
import 'package:marinette/app/core/theme/app_theme.dart';
import 'package:marinette/app/data/services/result_saver_service.dart';
import 'package:marinette/app/data/services/user_preferences_service.dart';
import 'package:marinette/app/data/services/content_service.dart';
import 'package:marinette/app/data/services/notification_service.dart';
import 'package:marinette/app/data/services/background_music_handler.dart';
import 'package:marinette/config/translations/app_translations.dart';

Future<void> main() async {
  try {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize services in correct order
    await _initializeServices();

    runApp(const BeautyRecommendationsApp());
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    runApp(_buildErrorApp(e.toString()));
  }
}

Future<void> _initializeServices() async {
  // 1. Initialize Hive (required for local storage)
  await Hive.initFlutter();
  debugPrint('Hive initialized');

  // 2. Initialize UserPreferences (other services might depend on user settings)
  await Get.putAsync(
    () => UserPreferencesService().init(),
    permanent: true,
  );
  debugPrint('UserPreferences service initialized');

  // 3. Initialize core services concurrently
  await Future.wait([
    // LocalizationService for translations
    Get.putAsync(
      () => LocalizationService().init(),
      permanent: true,
    ).then((_) => debugPrint('Localization service initialized')),

    // ContentService for app content
    Get.putAsync(
      () => ContentService().init(),
      permanent: true,
    ).then((_) => debugPrint('Content service initialized')),

    // ResultSaverService for storing analysis results
    Get.putAsync(
      () => ResultSaverService().init(),
      permanent: true,
    ).then((_) => debugPrint('ResultSaver service initialized')),
  ]);

  // 4. Initialize background music (after other core services)
  await BackgroundMusicHandler.instance.init();
  debugPrint('Background music handler initialized');

  // 5. Initialize notifications (last, as it's less critical)
  await NotificationService.initialize();
  debugPrint('Notification service initialized');
}

MaterialApp _buildErrorApp(String errorMessage) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error Initializing App',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class BeautyRecommendationsApp extends StatelessWidget {
  const BeautyRecommendationsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Beauty Recommendations',
      theme: AppTheme.theme,
      translations: AppTranslations(),
      locale: const Locale('uk'),
      fallbackLocale: const Locale('en'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('uk'),
      ],
      home: const HomeScreen(),
    );
  }
}
