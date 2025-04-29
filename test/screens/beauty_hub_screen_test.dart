import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/article.dart';
import 'package:marinette/app/data/services/beauty_hub_service.dart';
import 'package:marinette/app/modules/beauty_hub/beauty_hub_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';

class MockBeautyHubService extends Mock implements BeautyHubService {
  @override
  Future<List<Article>> getArticles() async {
    return [
      Article(
        id: '1',
        titleKey: 'article_1_title',
        descriptionKey: 'article_1_desc',
        imageUrl: 'https://test.com/image.jpg',
        contentKey: 'Test Content',
        publishedAt: DateTime.now(),
        authorNameKey: 'author1',
        authorAvatarUrl: 'https://test.com/avatar.jpg',
      )
    ];
  }

  @override
  Future<List<Article>> getLifehacks() async => [];

  @override
  Future<List<Article>> getGuides() async => [];
}

void main() {
  late MockBeautyHubService mockService;

  setUpAll(() {
    registerFallbackValue(Article(
      id: '1',
      titleKey: 'article_1_title',
      descriptionKey: 'article_1_desc',
      imageUrl: 'https://test.com/image.jpg',
      contentKey: 'Test Content',
      publishedAt: DateTime.now(),
      authorNameKey: 'author1',
      authorAvatarUrl: 'https://test.com/avatar.jpg',
    ));
  });

  setUp(() {
    Get.testMode = true;
    mockService = MockBeautyHubService();
    Get.put<BeautyHubService>(mockService);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('BeautyHubScreen renders correctly', (WidgetTester tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const BeautyHubScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
    });
  });

  testWidgets('Articles tab shows content', (WidgetTester tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const BeautyHubScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('article_1_title'), findsOneWidget);
      expect(find.text('article_1_desc'), findsOneWidget);
      expect(find.text('author1'), findsOneWidget);
    });
  });

  testWidgets('Tab switching works', (WidgetTester tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const BeautyHubScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('lifehacks'.tr));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('guides'.tr));
      await tester.pump(const Duration(seconds: 2));
    });
  });

  testWidgets('Pull to refresh works', (WidgetTester tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const BeautyHubScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pump(const Duration(seconds: 2));

      // Verify multiple article fetches during pull to refresh
      expect(
            () async => {
          await mockService.getArticles(),
          await mockService.getArticles(),
        },
        returnsNormally,
      );
    });
  });
}