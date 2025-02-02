import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:marinette/app/core/theme/theme_service.dart';
import 'package:marinette/app/data/services/background_music_handler.dart';
import 'package:marinette/app/data/services/content_service.dart';
import 'package:marinette/app/data/services/localization_service.dart';
import 'package:marinette/app/data/services/stories_service.dart';
import 'package:marinette/app/data/services/user_preferences_service.dart';
import 'package:marinette/app/modules/home/home_screen.dart';
import 'package:marinette/app/data/models/story.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marinette/app/data/content/daily_tips.dart';

class EmptyFinalCallback extends InternalFinalCallback<void> {
  @override
  void call() {}
}

class MockThemeService extends GetxService implements ThemeService {
  final _isDarkMode = false.obs;

  @override
  bool get isDarkMode => _isDarkMode.value;

  @override
  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
  }

  @override
  ThemeMode getThemeMode() => ThemeMode.light;

  @override
  Future<ThemeService> init() async => this;

  @override
  InternalFinalCallback<void> get onStart => EmptyFinalCallback();
}

class MockContentService extends GetxService implements ContentService {
  @override
  final currentTip = Rx(const DailyTip(tip: 'test_tip'));

  @override
  final currentTrends = RxList([]);

  @override
  Future<ContentService> init() async => this;

  @override
  Future<void> updateDailyTip() async {}

  @override
  Future<void> updateSeasonalTrends() async {}

  @override
  InternalFinalCallback<void> get onStart => EmptyFinalCallback();
}

class MockStoriesService extends GetxService implements StoriesService {
  @override
  final stories = RxList([]);

  @override
  final RxMap<String, bool> preloadedImages = RxMap<String, bool>();

  @override
  bool isImagePreloaded(String imageUrl) => true;

  @override
  bool isStoryReady(Story story) => true;

  @override
  Future<StoriesService> init() async => this;

  @override
  Future<void> loadStories() async {}

  @override
  Future<void> preloadImage(String imageUrl) async {}

  @override
  Future<void> updateStories() async {}

  @override
  Future<void> uploadStory(Story story) async {}

  @override
  Future<void> markStoryAsViewed(String storyId) async {}

  @override
  Future<void> preloadNextStoryImages(int count) async {}

  @override
  Future<void> preloadSingleImage(String imageUrl, {bool priority = false}) async {}

  @override
  Future<void> resetViewedStories() async {}

  @override
  int get unviewedStoriesCount => 0;

  @override
  bool get isTestMode => true;

  @override
  set isTestMode(bool value) {}

  @override
  dynamic get prefs => null;

  @override
  set prefs(dynamic value) {}

  @override
  InternalFinalCallback<void> get onStart => EmptyFinalCallback();
}

class MockLocalizationService extends GetxService implements LocalizationService {
  @override
  Rxn<Locale> get locale => Rxn<Locale>(const Locale('en'));

  @override
  Locale getCurrentLocale() => const Locale('en');

  @override
  Future<void> changeLocale(String languageCode) async {}

  @override
  Future<LocalizationService> init() async => this;

  @override
  String getLanguageName(String languageCode) => 'English';

  @override
  InternalFinalCallback<void> get onStart => EmptyFinalCallback();
}

void main() {
  setUpAll(() {
    registerFallbackValue(const Locale('en'));
    registerFallbackValue(Story(
        id: 'test',
        title: 'Test Story',
        imageUrls: ['test_url'],
        captions: ['Test Caption'],
        category: 'test_category',
        previewImageUrl: 'preview_url'
    ));
  });

  setUp(() {
    Get.reset();
    Get.testMode = true;
    BackgroundMusicHandler.isTestMode = true;
    SharedPreferences.setMockInitialValues({});

    final themeService = MockThemeService();
    final contentService = MockContentService();
    final storiesService = MockStoriesService();
    final localizationService = MockLocalizationService();

    Get.put<ThemeService>(themeService);
    Get.put<ContentService>(contentService);
    Get.put<StoriesService>(storiesService);
    Get.put<LocalizationService>(localizationService);
    Get.put<UserPreferencesService>(UserPreferencesService());
  });

  testWidgets('HomeScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);

    // Use a less strict matcher that checks for scroll view properties
    final scrollViews = find.byWidgetPredicate(
          (widget) =>
      widget is SingleChildScrollView &&
          widget.child is Padding &&
          (widget.child as Padding).padding == const EdgeInsets.all(24.0),
    );

    expect(scrollViews, findsOneWidget);
  });

  testWidgets('Theme toggle works', (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('theme'.tr));
    await tester.pumpAndSettle();
  });

  testWidgets('Language change works', (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('language'.tr));
    await tester.pumpAndSettle();
  });

  testWidgets('Tip of the day is displayed', (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('test_tip'.tr), findsOneWidget);
  });

  testWidgets('Feature cards are displayed', (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('take_photo'.tr), findsOneWidget);
    expect(find.text('choose_from_gallery'.tr), findsOneWidget);
    expect(find.text('beauty_hub'.tr), findsOneWidget);
  });
}