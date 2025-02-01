import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:marinette/app/data/models/article.dart';

class ArticleDetailsScreen extends StatelessWidget {
  final Article article;

  const ArticleDetailsScreen({
    super.key,
    required this.article,
  });

  String _getFullContent() {
    switch (article.id) {
      case '1':
        return 'article_1_full'.tr;
      case '2':
        return 'article_2_full'.tr;
      case '3':
        return 'article_3_full'.tr;
      case '4':
        return 'article_4_full'.tr;
      case '5':
        return 'article_5_full'.tr;
      case '6':
        return 'article_6_full'.tr;
      case 'l1':
        return 'lifehack_2_full'.tr;
      case 'l2':
        return 'lifehack_1_full'.tr;
      case 'l3':
        return 'lifehack_3_full'.tr;
      case 'l4':
        return 'lifehack_4_full'.tr;
      case 'l5':
        return 'lifehack_5_full'.tr;
      case 'l6':
        return 'lifehack_6_full'.tr;
      case 'g1':
        return 'guide_1_full'.tr;
      case 'g2':
        return 'guide_2_full'.tr;
      case 'g3':
        return 'guide_3_full'.tr;
      case 'g4':
        return 'guide_4_full'.tr;
      case 'g5':
        return 'guide_5_full'.tr;
      case 'g6':
        return 'guide_6_full'.tr;
      default:
        return article.contentKey.tr;
    }
  }

  int _calculateReadTime() {
    const wordsPerMinute = 120;
    final fullContent = _getFullContent();
    final wordCount = fullContent.split(RegExp(r'\s+')).length;
    return (wordCount / wordsPerMinute).ceil();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'today'.tr;
    if (difference == 1) return 'yesterday'.tr;
    return '$difference ${'days_ago'.tr}';
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
                    CachedNetworkImage(
                      imageUrl: article.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.error_outline,
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: article.authorAvatarUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, error, stackTrace) =>
                            const Icon(Icons.person),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.authorNameKey.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDate(article.publishedAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _getFullContent(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    ),
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