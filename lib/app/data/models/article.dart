// lib/app/data/models/article.dart

class Article {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final String imageUrl;
  final String contentKey;
  final DateTime publishedAt;
  final String authorNameKey;
  final String authorAvatarUrl;
  final bool isVisible; // Добавлено новое поле

  Article({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.imageUrl,
    required this.contentKey,
    required this.publishedAt,
    required this.authorNameKey,
    required this.authorAvatarUrl,
    this.isVisible = true, // По умолчанию статья видимая
  });

  // Метод для создания копии с обновленными полями
  Article copyWith({
    String? titleKey,
    String? descriptionKey,
    String? imageUrl,
    String? contentKey,
    DateTime? publishedAt,
    String? authorNameKey,
    String? authorAvatarUrl,
    bool? isVisible,
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
      isVisible: isVisible ?? this.isVisible,
    );
  }

  // Метод для конвертации в Map для Firebase
  Map<String, dynamic> toMap() {
    return {
      'title': titleKey,
      'description': descriptionKey,
      'imageUrl': imageUrl,
      'content': contentKey,
      'publishedAt': publishedAt,
      'authorName': authorNameKey,
      'authorAvatarUrl': authorAvatarUrl,
      'isVisible': isVisible,
    };
  }
}