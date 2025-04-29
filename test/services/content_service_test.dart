import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/content/daily_tips.dart';
import 'package:marinette/app/data/content/beauty_trends.dart';
import 'package:marinette/app/data/services/content_service.dart';

void main() {
  late ContentService contentService;

  setUp(() {
    Get.testMode = true;
    contentService = ContentService();
  });

  tearDown(() {
    Get.reset();
  });

  test('ContentService initializes with default values', () {
    expect(contentService.currentTip.value, equals(dailyTips[0]));
    expect(contentService.currentTrends, isEmpty);
  });

  test('updateDailyTip sets tip based on day of year', () {
    contentService.updateDailyTip();
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    final expectedTipIndex = dayOfYear % dailyTips.length;

    expect(contentService.currentTip.value, equals(dailyTips[expectedTipIndex]));
  });

  test('updateSeasonalTrends sets trends based on current season', () {
    contentService.updateSeasonalTrends();

    final currentMonth = DateTime.now().month;
    String expectedSeason;

    if (currentMonth >= 3 && currentMonth <= 5) {
      expectedSeason = 'spring';
    } else if (currentMonth >= 6 && currentMonth <= 8) {
      expectedSeason = 'summer';
    } else if (currentMonth >= 9 && currentMonth <= 11) {
      expectedSeason = 'autumn';
    } else {
      expectedSeason = 'winter';
    }

    final expectedTrends = beautyTrends.where((trend) => trend.season == expectedSeason).toList();
    expect(contentService.currentTrends, equals(expectedTrends));
  });

  test('init initializes service correctly', () async {
    await contentService.init();

    expect(contentService.currentTip.value, isNotNull);
    expect(contentService.currentTrends, isNotEmpty);
  });
}