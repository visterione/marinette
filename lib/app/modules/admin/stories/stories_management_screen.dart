// lib/app/modules/admin/stories/stories_management_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marinette/app/data/models/story.dart';
import 'package:marinette/app/data/services/stories_service.dart';
import 'package:marinette/app/modules/admin/stories/story_edit_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoriesManagementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StoriesService _storiesService = Get.find<StoriesService>();

  final RxList<Story> stories = <Story>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    loadStories();
  }

  Future<void> loadStories() async {
    isLoading.value = true;
    try {
      await _storiesService.loadStories();
      stories.value = _storiesService.stories;
    } catch (e) {
      debugPrint('Error loading stories: $e');
      Get.snackbar(
        'error'.tr,
        'error_loading_stories'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteStory(String storyId) async {
    try {
      isLoading.value = true;
      final success = await _storiesService.deleteStory(storyId);

      if (success) {
        Get.snackbar(
          'success'.tr,
          'story_deleted'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'error_deleting_story'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      return success;
    } catch (e) {
      debugPrint('Error deleting story: $e');
      Get.snackbar(
        'error'.tr,
        'error_deleting_story'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reorderStories(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final story = stories.removeAt(oldIndex);
    stories.insert(newIndex, story);

    // Обновление порядка в базе данных
    try {
      isLoading.value = true;

      // Обновляем порядок для всех историй
      for (int i = 0; i < stories.length; i++) {
        await _firestore.collection('stories').doc(stories[i].id).update({
          'order': i,
        });
      }

      Get.snackbar(
        'success'.tr,
        'stories_reordered'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error reordering stories: $e');
      Get.snackbar(
        'error'.tr,
        'error_reordering_stories'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );

      // В случае ошибки загружаем истории заново
      await loadStories();
    } finally {
      isLoading.value = false;
    }
  }

  List<Story> getFilteredStories() {
    final query = searchQuery.value.toLowerCase();
    var filteredStories = stories.toList();

    // Фильтрация по категории
    if (selectedCategory.value != 'all') {
      filteredStories = filteredStories
          .where((story) => story.category == selectedCategory.value)
          .toList();
    }

    // Фильтрация по поисковому запросу
    if (query.isNotEmpty) {
      filteredStories = filteredStories
          .where((story) => story.title.toLowerCase().contains(query))
          .toList();
    }

    return filteredStories;
  }

  List<String> getCategories() {
    final categories = <String>{'all'};

    for (final story in stories) {
      if (story.category.isNotEmpty) {
        categories.add(story.category);
      }
    }

    return categories.toList();
  }
}

class StoriesManagementScreen extends StatelessWidget {
  final controller = Get.put(StoriesManagementController());

  StoriesManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('manage_stories'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadStories,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Создание новой истории
          Get.to(() => StoryEditScreen(
            onSave: () => controller.loadStories(),
          ));
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Фильтры и поиск
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Поисковая строка
                TextField(
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

                const SizedBox(height: 12),

                // Выпадающий список категорий
                Obx(() {
                  final categories = controller.getCategories();

                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'filter_by_category'.tr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    value: controller.selectedCategory.value,
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category == 'all' ? 'all_categories'.tr : category,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.selectedCategory.value = value;
                      }
                    },
                  );
                }),
              ],
            ),
          ),

          // Список историй
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final stories = controller.getFilteredStories();

              if (stories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_stories,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.searchQuery.value.isNotEmpty || controller.selectedCategory.value != 'all'
                            ? 'no_search_results'.tr
                            : 'no_stories'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Используем ReorderableListView для возможности перетаскивания
              return ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: stories.length,
                onReorder: controller.reorderStories,
                itemBuilder: (context, index) => _buildStoryItem(context, stories[index], index),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(BuildContext context, Story story, int index) {
    return Card(
      key: Key(story.id),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Редактирование существующей истории
          Get.to(() => StoryEditScreen(
            story: story,
            onSave: () => controller.loadStories(),
          ));
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Верхняя часть с превью и заголовком
            Row(
              children: [
                // Превью изображение
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: story.previewImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: story.previewImageUrl,
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
                          size: 32,
                          color: Colors.grey,
                        ),
                      ),
                    )
                        : Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image,
                        size: 32,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

                // Информация о истории
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${'category'.tr}: ${story.category.isEmpty ? 'not_specified'.tr : story.category}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${'slides'.tr}: ${story.imageUrls.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${'position'.tr}: ${index + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Иконка для перетаскивания
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.drag_handle,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),

            // Миниатюры слайдов
            if (story.imageUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: story.imageUrls.asMap().entries.map((entry) {
                      final index = entry.key;
                      final imageUrl = entry.value;

                      return Container(
                        width: 80,
                        height: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.error_outline,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // Кнопки действий
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Кнопка редактирования
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Get.to(() => StoryEditScreen(
                        story: story,
                        onSave: () => controller.loadStories(),
                      ));
                    },
                  ),

                  // Кнопка удаления
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Диалог подтверждения удаления
                      Get.dialog(
                        AlertDialog(
                          title: Text('confirm_delete'.tr),
                          content: Text('confirm_delete_story'.tr),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: Text('cancel'.tr),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.back();
                                controller.deleteStory(story.id);
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
            ),
          ],
        ),
      ),
    );
  }
}