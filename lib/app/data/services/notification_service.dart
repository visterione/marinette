import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Initialize notification service
  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('app_icon');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
  }

  // Schedule a daily notification at a specific time
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour, minute),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_notification',
            'Daily Beauty Tips',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_tip',
      );
    } catch (e) {
      // Use debugPrint for development logging
      debugPrint('Error scheduling notification: $e');
    }
  }

  // Calculate the next occurrence of a specific time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}

// Helper class to generate beauty tips in Ukrainian
class BeautyTipGenerator {
  static final List<String> _ukrainianBeautyTips = [
    'Випивайте щодня не менше 8 склянок води для сяючої шкіри',
    'Завжди знімайте макіяж перед сном',
    'Використовуйте сонцезахисний крем щодня, навіть у хмарну погоду',
    'Видаляйте мертві клітини шкіри раз на тиждень',
    'Спіть 7-9 годин для здоров\'я шкіри',
    'Їжте багато фруктів та овочів для природньої краси',
    'Підтримуйте водний баланс для свіжості шкіри',
    'Використовуйте шовкову наволочку для зменшення тертя шкіри',
    'Робіть масаж обличчя для покращення кровообігу',
    'Наносьте зволожуючий крем одразу після душу',
    'Захищайте шкіру від синього світла екранів',
    'Використовуйте сироватку з вітаміном C для сяйва шкіри',
    'Не забувайте про шию та декольте у догляді за шкірою',
    'Вживайте продукти багаті антиоксидантами',
    'Практикуйте техніки зняття стресу, наприклад, медитацію',
  ];

  static String getRandomTip() {
    return _ukrainianBeautyTips[
        DateTime.now().millisecondsSinceEpoch % _ukrainianBeautyTips.length];
  }
}
