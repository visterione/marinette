import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final FlutterDriver driver = await FlutterDriver.connect(
    printCommunication: true,
    timeout: const Duration(minutes: 1),
  );

  try {
    // Перевіряємо стан драйвера
    final health = await driver.checkHealth();
    if (health.status == HealthStatus.bad) {
      throw Exception('Flutter Driver health check failed.');
    }
    print('Flutter Driver health check passed.');

    // Запускаємо тести
    await integrationDriver(
      driver: driver,
      onScreenshot: (String screenshotName, List<int> screenshotBytes, [Map<String, Object?>? args]) async {
        return true;
      },
    );
  } catch (e) {
    print('Test error: $e');
    rethrow;
  } finally {
    await driver.close();
  }
}