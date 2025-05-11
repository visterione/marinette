// lib/app/data/models/daily_tip.dart

class DailyTip {
  final String id;
  final String tip;
  final String icon;
  final int order;
  final bool isHidden;  // Добавляем флаг видимости

  DailyTip({
    required this.id,
    required this.tip,
    this.icon = '💡',
    this.order = 0,
    this.isHidden = false,  // По умолчанию элемент видимый
  });

  // Конвертация в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'tip': tip,
      'icon': icon,
      'order': order,
      'isHidden': isHidden,  // Добавляем поле в Firestore
    };
  }

  // Создание из Firestore данных
  factory DailyTip.fromFirestore(String id, Map<String, dynamic> data) {
    return DailyTip(
      id: id,
      tip: data['tip'] ?? '',
      icon: data['icon'] ?? '💡',
      order: data['order'] ?? 0,
      isHidden: data['isHidden'] ?? false,  // Получаем значение из Firestore
    );
  }

  // Создание копии с обновлёнными данными
  DailyTip copyWith({
    String? tip,
    String? icon,
    int? order,
    bool? isHidden,  // Добавляем параметр в copyWith
  }) {
    return DailyTip(
      id: this.id,
      tip: tip ?? this.tip,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      isHidden: isHidden ?? this.isHidden,  // Обновляем поле
    );
  }
}