import 'package:get/get.dart';
import 'package:marinette/app/data/content/daily_tips.dart';
import 'package:marinette/app/data/content/beauty_trends.dart';

class ContentService extends GetxService {
  final Rx<DailyTip> currentTip = dailyTips[0].obs;
  final RxList<BeautyTrend> currentTrends = <BeautyTrend>[].obs;

  Future<ContentService> init() async {
    updateDailyTip();
    updateSeasonalTrends();
    return this;
  }

  void updateDailyTip() {
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    final tipIndex = dayOfYear % dailyTips.length;
    currentTip.value = dailyTips[tipIndex];
  }

  void updateSeasonalTrends() {
    final currentMonth = DateTime.now().month;
    String season;

    if (currentMonth >= 3 && currentMonth <= 5) {
      season = 'spring';
    } else if (currentMonth >= 6 && currentMonth <= 8) {
      season = 'summer';
    } else if (currentMonth >= 9 && currentMonth <= 11) {
      season = 'autumn';
    } else {
      season = 'winter';
    }

    final seasonalTrends =
        beautyTrends.where((trend) => trend.season == season).toList();
    currentTrends.value = seasonalTrends;
  }
}
