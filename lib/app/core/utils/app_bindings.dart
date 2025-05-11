// lib/app/core/utils/app_bindings.dart

import 'package:get/get.dart';
import 'package:marinette/app/data/services/storage_service.dart';
import 'package:marinette/app/data/services/beauty_trends_service.dart';
import 'package:marinette/app/data/services/daily_tips_service.dart';
import 'package:marinette/app/data/services/content_service.dart';
import 'package:marinette/app/data/services/stories_service.dart';
import 'package:marinette/app/data/services/result_saver_service.dart';
import 'package:marinette/app/data/services/auth_service.dart';
import 'package:marinette/app/data/services/user_preferences_service.dart';
import 'package:marinette/app/core/theme/theme_service.dart';
import 'package:marinette/app/data/services/localization_service.dart' as ls;
import 'package:marinette/app/data/services/firestore_analysis_service.dart';
import 'package:marinette/app/data/services/background_music_handler.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Базовые сервисы
    Get.putAsync(() => UserPreferencesService().init(), permanent: true);
    Get.putAsync(() => ThemeService().init(), permanent: true);
    Get.putAsync(() => ls.LocalizationService().init(), permanent: true);

    // Firebase сервисы
    Get.putAsync(() => StorageService().init(), permanent: true);
    Get.put(AuthService(), permanent: true);
    Get.putAsync(() => FirestoreAnalysisService().init(), permanent: true);

    // Сервисы контента - порядок важен!
    Get.putAsync(() => BeautyTrendsService().init(), permanent: true);
    Get.putAsync(() => DailyTipsService().init(), permanent: true);
    Get.putAsync(() => ContentService().init(), permanent: true);

    // Другие сервисы
    Get.put(StoriesService(), permanent: true);
    Get.putAsync(() => ResultSaverService().init(), permanent: true);

    // Инициализация фоновой музыки
    BackgroundMusicHandler.instance.init();
  }
}