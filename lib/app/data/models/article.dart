class Article {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final String imageUrl;
  final String contentKey;
  final DateTime publishedAt;

  Article({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.imageUrl,
    required this.contentKey,
    required this.publishedAt,
  });
}
