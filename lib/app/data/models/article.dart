class Article {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final String imageUrl;
  final String contentKey;
  final DateTime publishedAt;
  final String authorNameKey;
  final String authorAvatarUrl;

  Article({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.imageUrl,
    required this.contentKey,
    required this.publishedAt,
    required this.authorNameKey,
    required this.authorAvatarUrl,
  });
}