// lib/app/data/models/daily_tip.dart

class DailyTip {
  final String id;
  final String tip;
  final String icon;
  final int order;
  final bool isVisible; // Add visibility field

  DailyTip({
    required this.id,
    required this.tip,
    this.icon = '💡',
    this.order = 0,
    this.isVisible = true, // Default to visible
  });

  // Конвертация в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'tip': tip,
      'icon': icon,
      'order': order,
      'isVisible': isVisible, // Include visibility in Firestore data
    };
  }

  // Создание из Firestore данных
  factory DailyTip.fromFirestore(String id, Map<String, dynamic> data) {
    return DailyTip(
      id: id,
      tip: data['tip'] ?? '',
      icon: data['icon'] ?? '💡',
      order: data['order'] ?? 0,
      isVisible: data['isVisible'] ?? true, // Load visibility from Firestore
    );
  }

  // Создание копии с обновлёнными данными
  DailyTip copyWith({
    String? tip,
    String? icon,
    int? order,
    bool? isVisible,
  }) {
    return DailyTip(
      id: this.id,
      tip: tip ?? this.tip,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}