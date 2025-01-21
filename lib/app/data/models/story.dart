// story.dart
class Story {
  final String id;
  final String title;
  final List<String> imageUrls; // Список фото
  final List<String> captions; // Підписи до кожного фото
  final String category;
  final bool isViewed;
  final String previewImageUrl; // Превью для кружечка в списку

  Story({
    required this.id,
    required this.title,
    required this.imageUrls,
    required this.captions,
    required this.category,
    required this.previewImageUrl,
    this.isViewed = false,
  });
}
