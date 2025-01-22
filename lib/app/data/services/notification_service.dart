import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

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

class NotificationService {
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'beauty_tips',
          channelName: 'Beauty Tips',
          channelDescription: 'Daily beauty advice notifications',
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Public,
          defaultColor: Colors.teal,
          ledColor: Colors.teal,
          playSound: true,
          enableVibration: true,
        )
      ],
    );

    // Перевірка дозволів
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static Future<void> scheduleDailyNotifications() async {
    // Видаляємо попередні заплановані сповіщення
    await AwesomeNotifications().cancelAll();

    // Щоденні сповіщення
    await _scheduleNotification(
      id: 1,
      hour: 9,
      minute: 0,
      title: 'Ранкова порада краси 🌞',
    );

    await _scheduleNotification(
      id: 2,
      hour: 18,
      minute: 0,
      title: 'Денна порада краси 🌈',
    );

    await _scheduleNotification(
      id: 3,
      hour: 21,
      minute: 0,
      title: 'Вечірня порада краси ✨',
    );
  }

  static Future<void> _scheduleNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'beauty_tips',
        title: title,
        body: BeautyTipGenerator.getRandomTip(),
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true,
      ),
    );
  }
}
