// lib/app/data/services/content_service.dart

import 'package:get/get.dart';
import 'package:marinette/app/data/models/beauty_trend.dart';
import 'package:marinette/app/data/models/daily_tip.dart';
import 'package:marinette/app/data/services/beauty_trends_service.dart';
import 'package:marinette/app/data/services/daily_tips_service.dart';
import 'dart:math';

class ContentService extends GetxService {
  // Находим необходимые сервисы
  final BeautyTrendsService _trendsService = Get.find<BeautyTrendsService>();
  final DailyTipsService _tipsService = Get.find<DailyTipsService>();

  // Reactive variables
  late final Rx<DailyTip> currentTip;

  // Добавляем метод init
  Future<ContentService> init() async {
    // Инициализируем с дефолтным значением
    currentTip = Rx<DailyTip>(DailyTip(id: 'default', tip: 'stay_hydrated', icon: '💧'));

    // Загружаем текущий совет
    _initializeTip();

    return this;
  }

  void _initializeTip() {
    // Используем метод, который учитывает видимость советов
    currentTip.value = _tipsService.getCurrentDailyTip();
  }

  // Получение трендов текущего сезона (только видимые)
  List<BeautyTrend> get currentTrends {
    // Используем метод сервиса, который возвращает только видимые тренды
    return _trendsService.getCurrentSeasonTrends();
  }

  // Получение случайного совета (только из видимых)
  void getRandomTip() {
    final visibleTips = _tipsService.tips.where((tip) => tip.isVisible).toList();

    if (visibleTips.isEmpty) {
      // Если нет видимых советов, устанавливаем дефолтный
      currentTip.value = DailyTip(id: 'default', tip: 'stay_hydrated', icon: '💧');
      return;
    }

    final randomIndex = Random().nextInt(visibleTips.length);
    currentTip.value = visibleTips[randomIndex];
  }
}