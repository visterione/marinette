// lib/app/modules/admin/articles/articles_management_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marinette/app/data/models/article.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:marinette/app/data/services/beauty_hub_service.dart';
import 'package:marinette/app/modules/admin/articles/article_edit_screen_direct.dart';

class ArticlesManagementController extends GetxController {
  final BeautyHubService _beautyHubService = Get.put(BeautyHubService());
  final RxList<Article> articles = <Article>[].obs;
  final RxList<Article> lifehacks = <Article>[].obs;
  final RxList<Article> guides = <Article>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxInt selectedTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllContent();
  }

  Future<void> loadAllContent() async {
    isLoading.value = true;
    try {
      // Используем методы для админ-панели, чтобы получить все статьи, включая скрытые
      final futures = await Future.wait([
        BeautyHubService.getAllArticlesForAdmin(),
        BeautyHubService.getAllLifehacksForAdmin(),
        BeautyHubService.getAllGuidesForAdmin(),
      ]);

      articles.value = futures[0];
      lifehacks.value = futures[1];
      guides.value = futures[2];
    } catch (e) {
      debugPrint('Error loading content: $e');
      Get.snackbar(
        'error'.tr,
        'error_loading_articles'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> toggleArticleVisibility(Article article) async {
    try {
      isLoading.value = true;

      // Вызываем метод toggleArticleVisibility в BeautyHubService
      final newVisibility = !article.isVisible;
      final success = await _beautyHubService.toggleArticleVisibility(
          article.id,
          newVisibility
      );

      if (success) {
        // Обновляем статью в соответствующем списке
        _updateArticleInLists(article.copyWith(isVisible: newVisibility));

        Get.snackbar(
          'success'.tr,
          newVisibility ? 'article_visible'.tr : 'article_hidden'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'error_toggling_visibility'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      return success;
    } catch (e) {
      debugPrint('Error toggling article visibility: $e');
      Get.snackbar(
        'error'.tr,
        'error_toggling_visibility'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Вспомогательный метод для обновления статьи в списках
  void _updateArticleInLists(Article updatedArticle) {
    // Определяем, в каком списке находится статья
    if (articles.any((a) => a.id == updatedArticle.id)) {
      final index = articles.indexWhere((a) => a.id == updatedArticle.id);
      articles[index] = updatedArticle;
    } else if (lifehacks.any((a) => a.id == updatedArticle.id)) {
      final index = lifehacks.indexWhere((a) => a.id == updatedArticle.id);
      lifehacks[index] = updatedArticle;
    } else if (guides.any((a) => a.id == updatedArticle.id)) {
      final index = guides.indexWhere((a) => a.id == updatedArticle.id);
      guides[index] = updatedArticle;
    }
  }

  Future<bool> deleteArticle(String articleId) async {
    try {
      isLoading.value = true;
      final success = await _beautyHubService.deleteArticle(articleId);

      if (success) {
        // Удаляем из соответствующего списка
        articles.removeWhere((article) => article.id == articleId);
        lifehacks.removeWhere((article) => article.id == articleId);
        guides.removeWhere((article) => article.id == articleId);

        Get.snackbar(
          'success'.tr,
          'article_deleted'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'error_deleting_article'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      return success;
    } catch (e) {
      debugPrint('Error deleting article: $e');
      Get.snackbar(
        'error'.tr,
        'error_deleting_article'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  String getArticleType(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'article';
      case 1:
        return 'lifehack';
      case 2:
        return 'guide';
      default:
        return 'article';
    }
  }

  List<Article> getFilteredArticles() {
    final query = searchQuery.value.toLowerCase();
    List<Article> result;

    // Выбираем коллекцию в зависимости от вкладки
    switch (selectedTabIndex.value) {
      case 0:
        result = articles;
        break;
      case 1:
        result = lifehacks;
        break;
      case 2:
        result = guides;
        break;
      default:
        result = articles;
    }

    // Фильтруем по поисковому запросу
    if (query.isNotEmpty) {
      result = result.where((article) =>
      article.titleKey.toLowerCase().contains(query) ||
          article.descriptionKey.toLowerCase().contains(query)).toList();
    }

    return result;
  }
}

class ArticlesManagementScreen extends StatelessWidget {
  final controller = Get.put(ArticlesManagementController());

  ArticlesManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('manage_articles'.tr),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: controller.loadAllContent,
            ),
          ],
          bottom: TabBar(
            onTap: (index) => controller.selectedTabIndex.value = index,
            tabs: [
              Tab(text: 'articles'.tr),
              Tab(text: 'lifehacks'.tr),
              Tab(text: 'guides'.tr),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Создание новой статьи с типом, соответствующим выбранной вкладке
            Get.to(() => ArticleEditDirectScreen(
              articleType: controller.getArticleType(controller.selectedTabIndex.value),
              onSave: () => controller.loadAllContent(),
            ));
          },
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            // Поисковая строка
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'search'.tr,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) => controller.searchQuery.value = value,
              ),
            ),

            // Список статей
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final articles = controller.getFilteredArticles();

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
                          controller.searchQuery.value.isNotEmpty
                              ? 'no_search_results'.tr
                              : 'no_articles'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: articles.length,
                  itemBuilder: (context, index) => _buildArticleItem(context, articles[index]),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleItem(BuildContext context, Article article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              // Редактирование существующей статьи
              Get.to(() => ArticleEditDirectScreen(
                article: article,
                onSave: () => controller.loadAllContent(),
              ));
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Изображение
                if (article.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: article.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Информация о статье
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.titleKey.tr,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          // Добавляем серый цвет для скрытых статей
                          color: article.isVisible ? null : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        article.descriptionKey.tr,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          // Меняем цвет для скрытых статей
                          color: article.isVisible ? Colors.grey[600] : Colors.grey[400],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'ID: ${article.id}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),

                          // Кнопка изменения видимости
                          IconButton(
                            icon: Icon(
                              article.isVisible ? Icons.visibility : Icons.visibility_off,
                              color: article.isVisible ? Colors.green : Colors.grey,
                            ),
                            onPressed: () => controller.toggleArticleVisibility(article),
                          ),

                          // Кнопки действий
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Get.to(() => ArticleEditDirectScreen(
                                article: article,
                                onSave: () => controller.loadAllContent(),
                              ));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Диалог подтверждения удаления
                              Get.dialog(
                                AlertDialog(
                                  title: Text('confirm_delete'.tr),
                                  content: Text('confirm_delete_article'.tr),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(),
                                      child: Text('cancel'.tr),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Get.back();
                                        controller.deleteArticle(article.id);
                                      },
                                      child: Text(
                                        'delete'.tr,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Метка "Скрыто"
          if (!article.isVisible)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'hidden'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}