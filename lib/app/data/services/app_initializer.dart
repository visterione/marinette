import 'package:flutter/material.dart';
import 'package:marinette/app/data/services/notification_service.dart';

class AppInitializer {
  static Future<void> initializeApp() async {
    // Ініціалізація віджетів Flutter
    WidgetsFlutterBinding.ensureInitialized();

    // Ініціалізація сповіщень
    await NotificationService.initialize();

    // Планування щоденних порад
    await NotificationService.scheduleDailyNotifications();
  }
}
