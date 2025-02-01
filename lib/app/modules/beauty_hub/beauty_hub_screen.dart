import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/article.dart';
import 'package:marinette/app/data/services/beauty_hub_service.dart';
import 'package:marinette/app/modules/article/article_details_screen.dart';

class BeautyHubScreen extends StatefulWidget {
  const BeautyHubScreen({super.key});

  @override
  State<BeautyHubScreen> createState() => _BeautyHubScreenState();
}

class _BeautyHubScreenState extends State<BeautyHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RxBool _isLoading = false.obs;
  final RxList<Article> _articles = <Article>[].obs;
  final RxList<Article> _lifehacks = <Article>[].obs;
  final RxList<Article> _guides = <Article>[].obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    _isLoading.value = true;
    try {
      final futures = await Future.wait([
        BeautyHubService.getArticles(),
        BeautyHubService.getLifehacks(),
        BeautyHubService.getGuides(),
      ]);

      _articles.value = futures[0];
      _lifehacks.value = futures[1];
      _guides.value = futures[2];
    } catch (e) {
      debugPrint('Error loading content: $e');
      Get.snackbar(
        'error'.tr,
        'error_loading_articles'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void _openArticle(Article article) {
    Get.to(
      () => ArticleDetailsScreen(article: article),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  int _calculateReadTime(Article article) {
    const wordsPerMinute = 120;

    final fullContent = _getFullContent(article);
    final wordCount = fullContent.split(RegExp(r'\s+')).length;
    return (wordCount / wordsPerMinute).ceil();
  }

  String _getFullContent(Article article) {
    switch (article.id) {
    // Статті
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
    // Лайфхаки
      case 'l1':
        return 'lifehack_1_full'.tr;
      case 'l2':
        return 'lifehack_2_full'.tr;
      case 'l3':
        return 'lifehack_3_full'.tr;
      case 'l4':
        return 'lifehack_4_full'.tr;
      case 'l5':
        return 'lifehack_5_full'.tr;
      case 'l6':
        return 'lifehack_6_full'.tr;
    // Гайди
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
      appBar: AppBar(
        title: Text('beauty_hub'.tr),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w500,
          ),
          labelColor: Colors.pink,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.pink,
          indicatorWeight: 2,
          tabs: [
            Tab(text: 'articles'.tr),
            Tab(text: 'lifehacks'.tr),
            Tab(text: 'guides'.tr),
          ],
        ),
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildArticlesList(_articles),
            _buildArticlesList(_lifehacks),
            _buildArticlesList(_guides),
          ],
        );
      }),
    );
  }

  Widget _buildArticlesList(List<Article> articles) {
    if (articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'no_articles'.tr,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadContent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: articles.length,
        itemBuilder: (context, index) => _buildArticleCard(articles[index]),
      ),
    );
  }

  // В BeautyHubScreen
  Widget _buildArticleCard(Article article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openArticle(article),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl.isNotEmpty)
              Hero(
                tag: 'article_image_${article.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      article.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.titleKey.tr,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.descriptionKey.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        child: ClipOval(
                          child: Image.network(
                            article.authorAvatarUrl,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        article.authorNameKey.tr,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_calculateReadTime(article)} ${'min_read'.tr}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _formatDate(article.publishedAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _openArticle(article),
                        child: Text('read_more'.tr),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
