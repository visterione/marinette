class Article {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final String imageUrl;
  final String contentKey;
  final DateTime publishedAt;
  final String authorNameKey;
  final String authorAvatarUrl;
  final bool isHidden; // Добавляем флаг видимости

  Article({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.imageUrl,
    required this.contentKey,
    required this.publishedAt,
    required this.authorNameKey,
    required this.authorAvatarUrl,
    this.isHidden = false, // По умолчанию статья видимая
  });

  // Создание копии с измененными параметрами
  Article copyWith({
    String? titleKey,
    String? descriptionKey,
    String? imageUrl,
    String? contentKey,
    DateTime? publishedAt,
    String? authorNameKey,
    String? authorAvatarUrl,
    bool? isHidden,
  }) {
    return Article(
      id: this.id,
      titleKey: titleKey ?? this.titleKey,
      descriptionKey: descriptionKey ?? this.descriptionKey,
      imageUrl: imageUrl ?? this.imageUrl,
      contentKey: contentKey ?? this.contentKey,
      publishedAt: publishedAt ?? this.publishedAt,
      authorNameKey: authorNameKey ?? this.authorNameKey,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      isHidden: isHidden ?? this.isHidden,
    );
  }
}