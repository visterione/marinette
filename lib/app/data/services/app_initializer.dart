import 'package:flutter/material.dart';
import 'package:marinette/app/data/services/notification_service.dart';

class AppInitializer {
  static Future<void> initializeApp() async {
    // Initialize Notifications
    await NotificationService.initialize();

    // Schedule daily beauty tips
    await _scheduleDailyBeautyTips();
  }

  static Future<void> _scheduleDailyBeautyTips() async {
    // Schedule morning tip
    await NotificationService.scheduleDailyNotification(
      id: 1,
      title: 'Щоденна порада краси 🌟',
      body: BeautyTipGenerator.getRandomTip(),
      hour: 9,
      minute: 0,
    );

    // Schedule afternoon tip
    await NotificationService.scheduleDailyNotification(
      id: 2,
      title: 'Денна порада краси 🌞',
      body: BeautyTipGenerator.getRandomTip(),
      hour: 18,
      minute: 0,
    );

    // Schedule evening tip
    await NotificationService.scheduleDailyNotification(
      id: 3,
      title: 'Вечірня порада краси ✨',
      body: BeautyTipGenerator.getRandomTip(),
      hour: 21,
      minute: 0,
    );
  }
}
