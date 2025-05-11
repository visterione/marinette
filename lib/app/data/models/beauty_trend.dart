// lib/app/data/models/beauty_trend.dart

class BeautyTrend {
  final String id;
  final String title;
  final String description;
  final String season; // 'winter', 'spring', 'summer', 'autumn'
  final int order;
  final bool isHidden; // Добавляем флаг видимости

  BeautyTrend({
    required this.id,
    required this.title,
    required this.description,
    required this.season,
    this.order = 0,
    this.isHidden = false, // По умолчанию тренд видимый
  });

  // Конвертация в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'season': season,
      'order': order,
      'isHidden': isHidden, // Добавляем поле в Firestore
    };
  }

  // Создание из Firestore данных
  factory BeautyTrend.fromFirestore(String id, Map<String, dynamic> data) {
    return BeautyTrend(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      season: data['season'] ?? 'spring',
      order: data['order'] ?? 0,
      isHidden: data['isHidden'] ?? false, // Получаем значение из Firestore
    );
  }

  // Создание копии с обновлёнными данными
  BeautyTrend copyWith({
    String? title,
    String? description,
    String? season,
    int? order,
    bool? isHidden, // Добавляем параметр в copyWith
  }) {
    return BeautyTrend(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      season: season ?? this.season,
      order: order ?? this.order,
      isHidden: isHidden ?? this.isHidden, // Обновляем поле
    );
  }
}