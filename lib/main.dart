import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:marinette/app/modules/home/home_screen.dart';
import 'package:marinette/app/core/theme/app_theme.dart';
import 'package:marinette/app/data/services/result_saver_service.dart';
import 'package:marinette/config/translations/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await Hive.initFlutter();
  await Get.putAsync(() => LocalizationService().init());
  await Get.putAsync(() => ResultSaverService().init());

  runApp(const BeautyRecommendationsApp());
}

class BeautyRecommendationsApp extends StatelessWidget {
  const BeautyRecommendationsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationService = Get.find<LocalizationService>();

    return GetMaterialApp(
      title: 'Marinette',
      theme: AppTheme.theme,
      translations: AppTranslations(),
      locale: Locale(localizationService.getCurrentLocale()),
      fallbackLocale: const Locale('uk'),
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
