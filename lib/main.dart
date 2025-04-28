// Оновлення основного файлу main.dart для ініціалізації Firebase

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
import 'package:marinette/app/modules/home/home_screen.dart';
import 'package:marinette/config/translations/app_translations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/data/services/stories_service.dart';
import 'firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');

    }

    await Messages.loadTranslations();
    await _initializeServices();
    runApp(const MainApp());
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

Future<void> _initializeServices() async {
  await Hive.initFlutter();
  debugPrint('Hive initialized');

  await SharedPreferences.getInstance();
  debugPrint('SharedPreferences initialized');

  await Get.putAsync(() => UserPreferencesService().init());
  debugPrint('UserPreferences service initialized');

  await Get.putAsync(() => ThemeService().init());
  debugPrint('Theme service initialized');

  await Get.putAsync(() => ContentService().init());
  debugPrint('Content service initialized');

  // Ініціалізуємо AuthService
  Get.put(AuthService());
  debugPrint('Auth service initialized');

  // Спочатку ініціалізуємо LocalizationService
  await Get.putAsync(() => ls.LocalizationService().init());
  debugPrint('Localization service initialized');

  // Потім StoriesService
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
      home: const HomeScreen(),
    );
  }
}