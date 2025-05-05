import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:marinette/app/core/theme/theme_service.dart';
import 'package:marinette/app/data/services/content_service.dart';
import 'package:marinette/app/data/services/localization_service.dart';
import 'package:marinette/app/data/services/background_music_handler.dart';
import 'package:marinette/app/data/services/stories_service.dart';
import 'package:marinette/app/data/services/user_preferences_service.dart';
import 'package:marinette/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Встановлення системних моків
    _setupSystemChannelMocks();

    // Встановлення тестового режиму
    BackgroundMusicHandler.isTestMode = false;

    // Встановлення тестового HTTP-оточення
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() async {
    await _initializeTestEnvironment();
  });

  tearDown(() async {
    await _cleanupTestEnvironment();
  });

  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MainApp());

    // Очікування з більш м'яким обмеженням часу
    await tester.pump(const Duration(seconds: 5));

    // Базові перевірки UI
    expect(find.byType(MaterialApp), findsOneWidget);

    // Перевірка наявності основних екранних елементів
    expect(find.byType(Scaffold), findsWidgets);
    expect(find.byType(AppBar), findsWidgets);
  });
}

void _setupSystemChannelMocks() {
  // Моки для path_provider
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

  // Моки для Just Audio
  const MethodChannel('com.ryanheise.just_audio.methods')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'init':
      case 'disposeAllPlayers':
      case 'setVolume':
      case 'load':
      case 'setAudioSource':
      case 'setAsset':
        return {};
      default:
        return null;
    }
  });

  // Моки для мережевих зображень
  const MethodChannel('plugins.flutter.io/network_image')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    return true;
  });
}

Future<void> _initializeTestEnvironment() async {
  // Підготовка тестового середовища
  Get.testMode = true;
  Get.reset();

  // Створення тимчасової директорії
  final testDir = Directory.systemTemp.createTempSync('marinette_test_');

  // Ініціалізація Hive
  await Hive.initFlutter(testDir.path);

  // Налаштування SharedPreferences
  SharedPreferences.setMockInitialValues({});

  try {
    // Послідовна ініціалізація сервісів
    await Get.putAsync(() => UserPreferencesService().init());
    await Get.putAsync(() => ThemeService().init());
    await Get.putAsync(() => ContentService().init());
    await Get.putAsync(() => LocalizationService().init());

    // Реєстрація сервісів
    final storiesService = StoriesService();
    storiesService.isTestMode = true;
    Get.put(storiesService, permanent: true);

    // Безпечна ініціалізація музичного хендлера
    await _safeInitBackgroundMusicHandler();
  } catch (e) {
    print('Initialization error: $e');
  }
}

Future<void> _cleanupTestEnvironment() async {
  try {
    await BackgroundMusicHandler.instance.dispose();
    await Hive.close();
  } catch (e) {
    print('Cleanup error: $e');
  }
  Get.reset();
}

Future<void> _safeInitBackgroundMusicHandler() async {
  try {
    await BackgroundMusicHandler.instance.init();
  } catch (e) {
    print('Background Music Handler initialization error: $e');
  }
}

// Клас для обробки HTTP-запитів у тестовому середовищі
class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _TestHttpClient();
  }
}

// Тестовий HTTP-клієнт
class _TestHttpClient implements HttpClient {
  @override
  bool get autoUncompress => true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 30);

  @override
  int? maxConnectionsPerHost = 5;

  @override
  String? userAgent;

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _TestHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> openUrlAsync(String method, Uri url) async {
    return _TestHttpClientRequest();
  }

  // Інші методи HttpClient з порожньою реалізацією
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Тестовий HTTP-клієнт для запитів
class _TestHttpClientRequest implements HttpClientRequest {
  @override
  HttpHeaders get headers => _TestHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _TestHttpClientResponse();
  }

  // Інші методи HttpClientRequest з порожньою реалізацією
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Тестовий клас заголовків
class _TestHttpHeaders implements HttpHeaders {
  @override
  bool get chunkedTransferEncoding => false;

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  // Інші методи HttpHeaders з порожньою реалізацією
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Тестовий клас відповіді
class _TestHttpClientResponse implements HttpClientResponse {
  @override
  HttpHeaders get headers => _TestHttpHeaders();

  @override
  int get statusCode => 200;

  @override
  Future<T> drain<T>([T? futureValue]) async => futureValue as T;

  @override
  StreamSubscription<List<int>> listen(
      void Function(List<int> event)? onData, {
        Function? onError,
        void Function()? onDone,
        bool? cancelOnError,
      }) {
    return Stream<List<int>>.fromIterable([]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  // Інші методи HttpClientResponse з порожньою реалізацією
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}