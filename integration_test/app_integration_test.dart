import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:marinette/main.dart' as app;
import 'package:marinette/app/data/services/background_music_handler.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marinette/app/data/services/localization_service.dart';
import 'package:marinette/config/translations/app_translations.dart';

Future<void> waitForBuild(WidgetTester tester) async {
  // Чекаємо завантаження UI з таймаутом
  bool isLoaded = false;
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(seconds: 1));
    // Шукаємо будь-який контент
    if (find.byType(Card).evaluate().isNotEmpty ||
        find.byType(ListView).evaluate().isNotEmpty) {
      isLoaded = true;
      break;
    }
  }
  if (!isLoaded) {
    throw Exception('UI did not load within timeout');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Базова ініціалізація
    BackgroundMusicHandler.isTestMode = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    final tempDir = await getTemporaryDirectory();
    await Hive.initFlutter(tempDir.path);
    await Messages.loadTranslations();
  });

  tearDownAll(() async {
    // Очищення після всіх тестів
    await Hive.close();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.reset();
  });

  group('Basic App Tests', () {
    testWidgets('App launches and shows main screen', (WidgetTester tester) async {
      app.main();
      await waitForBuild(tester);

      // Перевіряємо основні елементи UI
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('App shows content', (WidgetTester tester) async {
      app.main();
      await waitForBuild(tester);

      // Перевіряємо наявність контенту
      expect(
          find.byType(Card).evaluate().length +
              find.byType(ListView).evaluate().length,
          greaterThan(0)
      );
    });

    testWidgets('App shows images', (WidgetTester tester) async {
      app.main();
      await waitForBuild(tester);

      // Перевіряємо завантаження зображень
      final imageWidgets = find.byType(Image);
      expect(imageWidgets, findsWidgets);
    });

    testWidgets('App handles gestures', (WidgetTester tester) async {
      app.main();
      await waitForBuild(tester);

      // Перевіряємо наявність інтерактивних елементів
      final gestureDetectors = find.byType(GestureDetector);
      expect(gestureDetectors, findsWidgets);

      // Перевіряємо наявність кнопок
      final buttons = find.byType(IconButton);
      expect(buttons, findsWidgets);
    });

    testWidgets('App scroll test', (WidgetTester tester) async {
      app.main();
      await waitForBuild(tester);

      // Знаходимо скролабельний контейнер
      final scrollable = find.byType(Scrollable).first;

      // Виконуємо скрол
      await tester.dragFrom(
          tester.getCenter(scrollable),
          const Offset(0.0, -300.0)
      );
      await tester.pumpAndSettle();

      // Скролимо назад
      await tester.dragFrom(
          tester.getCenter(scrollable),
          const Offset(0.0, 300.0)
      );
      await tester.pumpAndSettle();
    });
  });
}