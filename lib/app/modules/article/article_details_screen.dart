// article_details_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/article.dart';
import 'package:share_plus/share_plus.dart';

class ArticleDetailsScreen extends StatelessWidget {
  final Article article;

  const ArticleDetailsScreen({
    super.key,
    required this.article,
  });

  String _getFullContent() {
    switch (article.id) {
      // Попередні статті
      case '1':
        return 'colortype_full'.tr;
      case '2':
        return 'face_shape_full'.tr;
      case '3':
        return 'makeup_trends_full'.tr;
      case '4':
        return 'skincare_seasons_full'.tr;

      // Лайфхаки
      case 'l1':
        return 'eyebrows_full'.tr;
      case 'l2':
        return 'makeup_lasting_full'.tr;
      case 'l3':
        return 'dry_shampoo_full'.tr;
      case 'l4':
        return 'nails_full'.tr;

      // Гайди
      case 'g1':
        return 'face_shape_guide_full'.tr;
      case 'g2':
        return 'makeup_event_full'.tr;
      case 'g3':
        return 'skincare_basics_full'.tr;
      case 'g4':
        return 'wardrobe_colortype_full'.tr;

      // Якщо id не збігається, використовується вміст за замовчуванням
      default:
        return article.contentKey.tr;
    }
  }

  int _calculateReadTime() {
    const wordsPerMinute = 150;
    final fullContent = _getFullContent();
    final wordCount = fullContent.split(RegExp(r'\s+')).length;
    return (wordCount / wordsPerMinute).ceil();
  }

  String _getTimeAgo(DateTime publishedAt) {
    final now = DateTime.now();
    final difference = now.difference(publishedAt).inDays;

    if (difference == 0) return 'today'.tr;
    if (difference == 1) return 'yesterday'.tr;
    return '$difference ${'days_ago'.tr}';
  }

  Future<void> _shareArticle() async {
    try {
      final String shareText = '''
${article.titleKey.tr}

${article.descriptionKey.tr}

${_getFullContent()}

Shared from Beauty Recommendations App
''';

      await Share.share(
        shareText,
        subject: article.titleKey.tr,
      );
    } catch (e) {
      debugPrint('Error sharing article: $e');
      Get.snackbar(
        'error'.tr,
        'error_sharing'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'article_image_${article.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      article.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareArticle,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.titleKey.tr,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_calculateReadTime()} ${'min_read'.tr}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _getTimeAgo(article.publishedAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getFullContent(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
