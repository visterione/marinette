import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:marinette/app/modules/home/home_screen.dart';
import 'package:marinette/app/core/theme/app_theme.dart';
import 'package:marinette/app/data/services/result_saver_service.dart';
import 'package:marinette/app/data/services/user_preferences_service.dart';
import 'package:marinette/app/data/services/audio_service.dart';
import 'package:marinette/app/data/services/content_service.dart';
import 'package:marinette/config/translations/app_translations.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Hive
    await Hive.initFlutter();

    // Initialize essential services
    await Get.putAsync(() => LocalizationService().init());
    await Get.putAsync(() => UserPreferencesService().init());
    await Get.putAsync(() => ResultSaverService().init());
    await Get.putAsync(() => ContentService().init());

    // Initialize audio service in the background
    initAudioService();

    runApp(const BeautyRecommendationsApp());
  } catch (e) {
    debugPrint('Error during app initialization: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error initializing app: $e'),
        ),
      ),
    ));
  }
}

void initAudioService() {
  Future.delayed(const Duration(seconds: 2), () async {
    try {
      debugPrint('Starting audio service initialization');
      await Get.putAsync(
        () => AudioService().init(),
        permanent: true,
      );
      debugPrint('Audio service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize audio service: $e');
    }
  });
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
