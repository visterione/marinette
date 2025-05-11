// lib/app/data/models/story.dart

class Story {
  final String id;
  final String title;
  final List<String> imageUrls;
  final List<String> captions;
  final String category;
  final String previewImageUrl;
  bool isViewed;
  // Добавляем поле для видимости истории (по умолчанию - видимая)
  bool isVisible;

  Story({
    required this.id,
    required this.title,
    required this.imageUrls,
    required this.captions,
    required this.category,
    required this.previewImageUrl,
    this.isViewed = false,
    this.isVisible = true, // По умолчанию история видима
  });

  Story copyWith({
    String? id,
    String? title,
    List<String>? imageUrls,
    List<String>? captions,
    String? category,
    String? previewImageUrl,
    bool? isViewed,
    bool? isVisible, // Добавляем в copyWith
  }) {
    return Story(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrls: imageUrls ?? this.imageUrls,
      captions: captions ?? this.captions,
      category: category ?? this.category,
      previewImageUrl: previewImageUrl ?? this.previewImageUrl,
      isViewed: isViewed ?? this.isViewed,
      isVisible: isVisible ?? this.isVisible, // Используем в copyWith
    );
  }
}