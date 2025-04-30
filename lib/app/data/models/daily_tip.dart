// lib/app/data/models/daily_tip.dart

class DailyTip {
  final String id;
  final String tip;
  final String icon;
  final int order;

  DailyTip({
    required this.id,
    required this.tip,
    this.icon = '💡',
    this.order = 0,
  });

  // Конвертация в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'tip': tip,
      'icon': icon,
      'order': order,
    };
  }

  // Создание из Firestore данных
  factory DailyTip.fromFirestore(String id, Map<String, dynamic> data) {
    return DailyTip(
      id: id,
      tip: data['tip'] ?? '',
      icon: data['icon'] ?? '💡',
      order: data['order'] ?? 0,
    );
  }

  // Создание копии с обновлёнными данными
  DailyTip copyWith({
    String? tip,
    String? icon,
    int? order,
  }) {
    return DailyTip(
      id: this.id,
      tip: tip ?? this.tip,
      icon: icon ?? this.icon,
      order: order ?? this.order,
    );
  }
}