import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marinette/app/data/models/story.dart';
import 'package:marinette/app/data/services/stories_service.dart';
import 'package:marinette/app/data/services/localization_service.dart';

// Моки для тестування
class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockLocalizationService extends GetxService implements LocalizationService {
  final locale = Rxn<Locale>(const Locale('en'));

  @override
  Locale getCurrentLocale() => locale.value ?? const Locale('en');

  @override
  Future<void> changeLocale(String languageCode) async {}

  @override
  String getLanguageName(String languageCode) => 'English';

  @override
  Future<LocalizationService> init() async {
    return this;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Глобальні моки для системних каналів
  setUpAll(() {
    // Мок path_provider
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getTemporaryDirectory':
        case 'getApplicationSupportDirectory':
        case 'getApplicationDocumentsDirectory':
          return '.';
        default:
          return null;
      }
    });

    // Мок каналів зображень
    const MethodChannel('plugins.flutter.io/image_picker')
        .setMockMethodCallHandler((MethodCall methodCall) async => true);
  });

  late StoriesService storiesService;
  late MockSharedPreferences mockPrefs;
  late MockLocalizationService mockLocalization;

  setUp(() async {
    // Підготовка тестового середовища
    Get.testMode = true;
    Get.reset();

    // Створення моків
    mockPrefs = MockSharedPreferences();
    mockLocalization = MockLocalizationService();
    await mockLocalization.init();

    // Налаштування поведінки моків
    when(() => mockPrefs.getStringList(any())).thenReturn([]);
    when(() => mockPrefs.setStringList(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);

    // Реєстрація сервісів
    Get.put<LocalizationService>(mockLocalization);

    // Створення сервісу
    storiesService = StoriesService();
    storiesService.prefs = mockPrefs;
    storiesService.isTestMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('StoriesService Tests', () {
    test('Initial state should be empty', () {
      expect(storiesService.stories, isEmpty);
      expect(storiesService.preloadedImages, isEmpty);
    });

    test('loadStories should populate stories list', () async {
      await storiesService.loadStories();
      expect(storiesService.stories, isNotEmpty);
      expect(storiesService.stories.length, equals(5));
    });

    test('markStoryAsViewed should update story status', () async {
      await storiesService.loadStories();
      final story = storiesService.stories[0];

      expect(story.isViewed, isFalse);
      await storiesService.markStoryAsViewed(story.id);

      final updatedStory = storiesService.stories.firstWhere((s) => s.id == story.id);
      expect(updatedStory.isViewed, isTrue);
    });

    test('resetViewedStories completely clears viewed status', () async {
      // Завантажуємо історії
      await storiesService.loadStories();

      // Позначаємо історії як переглянуті
      for (var story in storiesService.stories) {
        await storiesService.markStoryAsViewed(story.id);
      }

      // Скидаємо статус переглянутих історій
      await storiesService.resetViewedStories();

      // Перевірка, що КОЖНА історія не переглянута
      expect(
          storiesService.stories.every((s) => !s.isViewed),
          isTrue,
          reason: 'All stories should be marked as not viewed after reset'
      );
    });

    test('preloadSingleImage works in test mode', () async {
      final testUrl = 'https://example.com/test.jpg';

      // Виклик методу попереднього завантаження
      await storiesService.preloadSingleImage(testUrl);

      // Перевірка, що зображення позначене як завантажене
      expect(storiesService.isImagePreloaded(testUrl), isTrue);
    });

    test('isStoryReady returns correct status', () async {
      await storiesService.loadStories();
      final story = storiesService.stories[0];

      // Спочатку історія не готова
      expect(storiesService.isStoryReady(story), isFalse);

      // Штучно встановлюємо зображення як попередньо завантажені
      await storiesService.preloadSingleImage(story.previewImageUrl);
      await storiesService.preloadSingleImage(story.imageUrls.first);

      // Тепер історія повинна бути готовою
      expect(storiesService.isStoryReady(story), isTrue);
    });
  });
}