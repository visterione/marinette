import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marinette/app/modules/home/home_screen.dart';
import 'package:marinette/app/core/theme/app_theme.dart';
import 'package:marinette/app/data/services/result_saver_service.dart';
import 'package:marinette/app/data/services/user_preferences_service.dart';
import 'package:marinette/app/data/services/content_service.dart';
import 'package:marinette/app/data/services/notification_service.dart';
import 'package:marinette/app/data/services/background_music_handler.dart';
import 'package:marinette/config/translations/app_translations.dart';
import 'package:marinette/app/core/theme/theme_service.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await _initializeServices();
    runApp(const BeautyRecommendationsApp());
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    runApp(_buildErrorApp(e.toString()));
  }
}

Future<void> _initializeServices() async {
  try {
    // Ініціалізуємо Hive
    await Hive.initFlutter();
    debugPrint('Hive initialized');

    // Ініціалізуємо SharedPreferences перед всіма сервісами
    await SharedPreferences.getInstance();
    debugPrint('SharedPreferences initialized');

    // Тепер ініціалізуємо сервіси
    await Get.putAsync(
      () => UserPreferencesService().init(),
      permanent: true,
    );
    debugPrint('UserPreferences service initialized');

    await Get.putAsync(
      () => ThemeService().init(),
      permanent: true,
    );
    debugPrint('Theme service initialized');

    // Ініціалізуємо інші сервіси паралельно
    await Future.wait([
      Get.putAsync(
        () => LocalizationService().init(),
        permanent: true,
      ).then((_) => debugPrint('Localization service initialized')),
      Get.putAsync(
        () => ContentService().init(),
        permanent: true,
      ).then((_) => debugPrint('Content service initialized')),
      Get.putAsync(
        () => ResultSaverService().init(),
        permanent: true,
      ).then((_) => debugPrint('ResultSaver service initialized')),
    ]);

    await BackgroundMusicHandler.instance.init();
    debugPrint('Background music handler initialized');

    await NotificationService.initialize();
    debugPrint('Notification service initialized');
  } catch (e) {
    debugPrint('Error during service initialization: $e');
    rethrow;
  }
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
    final themeService = Get.find<ThemeService>();

    return GetMaterialApp(
      title: 'Beauty Recommendations',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.getThemeMode(),
      translations: Messages(),
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
        Locale('pl'),
        Locale('ka'),
      ],
      home: const HomeScreen(),
    );
  }
}
