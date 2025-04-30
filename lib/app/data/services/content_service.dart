// lib/app/data/services/content_service.dart

import 'package:get/get.dart';
import 'package:marinette/app/data/models/daily_tip.dart';
import 'package:marinette/app/data/models/beauty_trend.dart';
import 'package:marinette/app/data/services/daily_tips_service.dart';
import 'package:marinette/app/data/services/beauty_trends_service.dart';

class ContentService extends GetxService {
  final DailyTipsService _tipsService = Get.put(DailyTipsService());
  final BeautyTrendsService _trendsService = Get.put(BeautyTrendsService());

  final Rx<DailyTip> currentTip = DailyTip(id: 'default', tip: 'stay_hydrated', icon: '💧').obs;
  final RxList<BeautyTrend> currentTrends = <BeautyTrend>[].obs;

  Future<ContentService> init() async {
    await _tipsService.init();
    await _trendsService.init();

    updateDailyTip();
    updateSeasonalTrends();
    return this;
  }

  void updateDailyTip() {
    currentTip.value = _tipsService.getCurrentDailyTip();
  }

  void updateSeasonalTrends() {
    currentTrends.value = _trendsService.getCurrentSeasonTrends();
  }
}