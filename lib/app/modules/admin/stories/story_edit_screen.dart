// lib/app/modules/admin/stories/story_edit_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marinette/app/data/models/story.dart';
import 'package:marinette/app/data/services/storage_service.dart';
import 'package:marinette/app/data/services/stories_service.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:reorderables/reorderables.dart';

class StoryEditController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final StorageService _storageService = Get.find<StorageService>();
  final StoriesService _storiesService = Get.find<StoriesService>();
  final ImagePicker _picker = ImagePicker();

  final Story? story;
  final Function? onSave;

  // Контроллеры для текстовых полей
  late TextEditingController titleController;
  late TextEditingController categoryController;

  // Реактивные переменные для отслеживания состояния
  final RxBool isLoading = false.obs;
  final RxString previewImageUrl = ''.obs;
  final Rxn<File> previewImageFile = Rxn<File>();
  final RxList<Map<String, dynamic>> slides = <Map<String, dynamic>>[].obs;

  StoryEditController({
    this.story,
    this.onSave,
  });

  @override
  void onInit() {
    super.onInit();

    // Инициализация контроллеров
    titleController = TextEditingController(text: story?.title ?? '');
    categoryController = TextEditingController(text: story?.category ?? '');

    if (story != null) {
      previewImageUrl.value = story!.previewImageUrl;

      // Инициализация списка слайдов из существующей истории
      for (int i = 0; i < story!.imageUrls.length; i++) {
        final caption = i < story!.captions.length ? story!.captions[i] : '';

        slides.add({
          'imageUrl': story!.imageUrls[i],
          'imageFile': null,
          'caption': caption,
          'captionController': TextEditingController(text: caption),
        });
      }
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    categoryController.dispose();

    // Освобождение контроллеров подписей слайдов
    for (final slide in slides) {
      (slide['captionController'] as TextEditingController).dispose();
    }

    super.onClose();
  }

  // Выбор изображения для превью
  Future<void> pickPreviewImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        previewImageFile.value = File(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Error picking preview image: $e');
      Get.snackbar(
        'error'.tr,
        'error_picking_image'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Добавление нового слайда
  Future<void> addSlide() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final captionController = TextEditingController();

        slides.add({
          'imageUrl': '',
          'imageFile': File(pickedFile.path),
          'caption': '',
          'captionController': captionController,
        });
      }
    } catch (e) {
      debugPrint('Error picking slide image: $e');
      Get.snackbar(
        'error'.tr,
        'error_picking_image'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Обновление подписи слайда
  void updateSlideCaption(int index, String caption) {
    if (index >= 0 && index < slides.length) {
      slides[index]['caption'] = caption;
    }
  }

  // Удаление слайда
  void removeSlide(int index) {
    if (index >= 0 && index < slides.length) {
      final slide = slides[index];

      // Освобождение контроллера подписи
      (slide['captionController'] as TextEditingController).dispose();

      slides.removeAt(index);
    }
  }

  // Изменение порядка слайдов
  void reorderSlides(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final slide = slides.removeAt(oldIndex);
    slides.insert(newIndex, slide);
  }

  // Загрузка изображения в Firebase Storage
  Future<String?> _uploadImage(File file, String folder) async {
    try {
      final fileName = '${const Uuid().v4()}${path.extension(file.path)}';
      final storageRef = _storage.ref().child('stories').child(folder).child(fileName);

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // Сохранение истории
  Future<void> saveStory() async {
    // Валидация полей
    if (titleController.text.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'title_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (slides.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'slides_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;

    try {
      String storyId = story?.id ?? '';
      String previewUrl = previewImageUrl.value;
      List<String> imageUrls = [];
      List<String> captions = [];

      // Загрузка превью, если оно было выбрано
      if (previewImageFile.value != null) {
        final uploadedPreviewUrl = await _uploadImage(previewImageFile.value!, 'previews');
        if (uploadedPreviewUrl != null) {
          previewUrl = uploadedPreviewUrl;
        }
      }

      // Если превью не выбрано и не существует, используем первый слайд как превью
      if (previewUrl.isEmpty && slides.isNotEmpty) {
        if (slides[0]['imageFile'] != null) {
          final uploadedPreviewUrl = await _uploadImage(slides[0]['imageFile'] as File, 'previews');
          if (uploadedPreviewUrl != null) {
            previewUrl = uploadedPreviewUrl;
          }
        } else if (slides[0]['imageUrl'] != null && slides[0]['imageUrl'].isNotEmpty) {
          previewUrl = slides[0]['imageUrl'];
        }
      }

      // Загрузка изображений слайдов
      for (final slide in slides) {
        String imageUrl = slide['imageUrl'] ?? '';
        final File? imageFile = slide['imageFile'];

        if (imageFile != null) {
          // Загрузка нового изображения
          final uploadedImageUrl = await _uploadImage(imageFile, 'slides');
          if (uploadedImageUrl != null) {
            imageUrl = uploadedImageUrl;
          }
        }

        if (imageUrl.isNotEmpty) {
          imageUrls.add(imageUrl);
          captions.add(slide['caption'] ?? '');
        }
      }

      Map<String, dynamic> storyData = {
        'title': titleController.text,
        'category': categoryController.text,
        'previewImageUrl': previewUrl,
        'imageUrls': imageUrls,
        'captions': captions,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (story == null) {
        // Создание новой истории
        storyData['createdAt'] = FieldValue.serverTimestamp();
        storyData['order'] = await _getNextStoryOrder();

        final docRef = await _firestore.collection('stories').add(storyData);
        storyId = docRef.id;

        Get.snackbar(
          'success'.tr,
          'story_created'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        // Обновление существующей истории
        await _firestore.collection('stories').doc(story!.id).update(storyData);

        Get.snackbar(
          'success'.tr,
          'story_updated'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      // Вызов колбэка при успешном сохранении
      if (onSave != null) {
        onSave!();
      }

      Get.back();
    } catch (e) {
      debugPrint('Error saving story: $e');
      Get.snackbar(
        'error'.tr,
        'error_saving_story'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Получение следующего порядкового номера для новой истории
  Future<int> _getNextStoryOrder() async {
    try {
      final snapshot = await _firestore.collection('stories')
          .orderBy('order', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final currentOrder = data['order'] ?? 0;
        return (currentOrder as int) + 1;
      }

      return 0;
    } catch (e) {
      debugPrint('Error getting next story order: $e');
      return _storiesService.stories.length;
    }
  }
}

class StoryEditScreen extends StatelessWidget {
  final Story? story;
  final Function? onSave;

  StoryEditScreen({
    Key? key,
    this.story,
    this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StoryEditController(
      story: story,
      onSave: onSave,
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(story == null ? 'create_story'.tr : 'edit_story'.tr),
        actions: [
          Obx(() => controller.isLoading.value
              ? Container(
            margin: const EdgeInsets.all(16),
            width: 24,
            height: 24,
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
              : IconButton(
            icon: const Icon(Icons.save),
            onPressed: controller.saveStory,
          ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основные поля
            _buildTextField(
              controller: controller.titleController,
              label: 'story_title'.tr,
              hint: 'story_title_hint'.tr,
              isRequired: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: controller.categoryController,
              label: 'story_category'.tr,
              hint: 'story_category_hint'.tr,
            ),
            const SizedBox(height: 24),

            // Превью изображение
            _buildPreviewImageSection(context, controller),
            const SizedBox(height: 24),

            // Слайды
            _buildSlidesSection(context, controller),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: maxLines,
        ),
      ],
    );
  }

  Widget _buildPreviewImageSection(BuildContext context, StoryEditController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'preview_image'.tr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'preview_image_description'.tr,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.previewImageFile.value != null) {
            // Отображение выбранного изображения для превью
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    controller.previewImageFile.value!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () => controller.previewImageFile.value = null,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16),
                    ),
                  ),
                ),
              ],
            );
          } else if (controller.previewImageUrl.value.isNotEmpty) {
            // Отображение существующего изображения для превью
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: controller.previewImageUrl.value,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.error_outline,
                        size: 32,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: controller.pickPreviewImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 16),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Кнопка выбора изображения для превью
            return InkWell(
              onTap: controller.pickPreviewImage,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 120,
                height: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image,
                      size: 32,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'select_preview'.tr,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
        }),
      ],
    );
  }

  Widget _buildSlidesSection(BuildContext context, StoryEditController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'story_slides'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: controller.addSlide,
              icon: const Icon(Icons.add),
              label: Text('add_slide'.tr),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'slides_description'.tr,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),

        // Список слайдов с возможностью перетаскивания
        Obx(() {
          if (controller.slides.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.slideshow,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'no_slides_yet'.tr,
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: controller.addSlide,
                      icon: const Icon(Icons.add),
                      label: Text('add_first_slide'.tr),
                    ),
                  ],
                ),
              ),
            );
          }

          return ReorderableColumn(
            onReorder: controller.reorderSlides,
            children: List.generate(controller.slides.length, (index) {
              final slide = controller.slides[index];
              final File? imageFile = slide['imageFile'];
              final String imageUrl = slide['imageUrl'] ?? '';
              final TextEditingController captionController = slide['captionController'];

              return Card(
                key: ValueKey('slide_$index'),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Превью слайда
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Изображение
                                if (imageFile != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      imageFile,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else if (imageUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(
                                        Icons.error_outline,
                                        size: 32,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                else
                                  const Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 32,
                                      color: Colors.grey,
                                    ),
                                  ),

                                // Номер слайда
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                // Иконка перетаскивания
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.drag_handle,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Подпись и кнопки
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: captionController,
                                  decoration: InputDecoration(
                                    labelText: 'slide_caption'.tr,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                  onChanged: (value) => controller.updateSlideCaption(index, value),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Кнопка удаления слайда
                                    TextButton.icon(
                                      onPressed: () => controller.removeSlide(index),
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      label: Text(
                                        'remove_slide'.tr,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}