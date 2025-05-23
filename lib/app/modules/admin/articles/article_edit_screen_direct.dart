// lib/app/modules/admin/articles/article_edit_screen_direct.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marinette/app/data/models/article.dart';
import 'package:marinette/app/data/services/storage_service.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ArticleModel {
  final String id;
  final String title;
  final String description;
  final String content;
  final String imageUrl;
  final DateTime publishedAt;
  final String authorName;
  final String authorAvatarUrl;
  final String type;
  final bool isVisible; // Добавлено поле видимости

  ArticleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.imageUrl,
    required this.publishedAt,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.type,
    this.isVisible = true, // По умолчанию статья видимая
  });

  // Создаем ключи на основе ID или UUID
  String get titleKey => title;
  String get descriptionKey => description;
  String get contentKey => content;
  String get authorNameKey => authorName;

  // Преобразование ArticleModel в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'imageUrl': imageUrl,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'type': type, // 'article', 'lifehack', или 'guide'
      'publishedAt': publishedAt,
      'isVisible': isVisible, // Добавляем поле видимости
    };
  }

  // Создание модели из Article
  factory ArticleModel.fromArticle(Article article, {String type = 'article'}) {
    return ArticleModel(
      id: article.id,
      title: article.titleKey,
      description: article.descriptionKey,
      content: article.contentKey,
      imageUrl: article.imageUrl,
      publishedAt: article.publishedAt,
      authorName: article.authorNameKey,
      authorAvatarUrl: article.authorAvatarUrl,
      type: type,
      isVisible: article.isVisible, // Используем поле видимости из статьи
    );
  }

  // Create a copy with updated fields
  ArticleModel copyWith({
    String? title,
    String? description,
    String? content,
    String? imageUrl,
    DateTime? publishedAt,
    String? authorName,
    String? authorAvatarUrl,
    String? type,
    bool? isVisible,
  }) {
    return ArticleModel(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      type: type ?? this.type,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

class ArticleEditDirectController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final StorageService _storageService = Get.find<StorageService>();
  final ImagePicker _picker = ImagePicker();

  final Article? article;
  final String? articleType;
  final Function? onSave;

  // Контроллеры для текстовых полей
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController contentController;
  late TextEditingController authorNameController;

  // Реактивные переменные
  final RxBool isLoading = false.obs;
  final RxString imageUrl = ''.obs;
  final Rxn<File> imageFile = Rxn<File>();
  final RxString selectedType = 'article'.obs;
  final RxBool isVisible = true.obs; // Добавлена переменная видимости

  // Определение списка доступных типов статей
  final List<Map<String, String>> articleTypes = [
    {'value': 'article', 'label': 'Article'},
    {'value': 'lifehack', 'label': 'Lifehack'},
    {'value': 'guide', 'label': 'Guide'},
  ];

  // Определение дефолтного URL для аватара автора
  static const String defaultAuthorAvatarUrl = 'https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.appspot.com/o/authors%2Fdefault_avatar.jpg?alt=media';

  ArticleEditDirectController({
    this.article,
    this.articleType,
    this.onSave,
  });

  @override
  void onInit() {
    super.onInit();

    // Инициализация контроллеров с непосредственным текстом, а не ключами
    titleController = TextEditingController(text: article != null ? article!.titleKey : '');
    descriptionController = TextEditingController(text: article != null ? article!.descriptionKey : '');
    contentController = TextEditingController(text: article != null ? article!.contentKey : '');
    authorNameController = TextEditingController(text: article != null ? article!.authorNameKey : 'Admin');

    // Инициализация типа статьи
    if (article != null) {
      // Определяем тип из существующей статьи
      if (article!.id.startsWith('l')) {
        selectedType.value = 'lifehack';
      } else if (article!.id.startsWith('g')) {
        selectedType.value = 'guide';
      } else {
        selectedType.value = 'article';
      }

      // Инициализируем видимость из статьи
      isVisible.value = article!.isVisible;
    } else if (articleType != null) {
      selectedType.value = articleType!;
    }

    if (article != null) {
      imageUrl.value = article!.imageUrl;
    }
  }

  // Переключение видимости статьи
  void toggleVisibility() {
    isVisible.value = !isVisible.value;
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    contentController.dispose();
    authorNameController.dispose();
    super.onClose();
  }

  // Выбор изображения
  Future<void> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        imageFile.value = File(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      Get.snackbar(
        'error'.tr,
        'error_picking_image'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Загрузка изображения
  Future<String?> _uploadImage() async {
    if (imageFile.value == null) return imageUrl.value;

    try {
      final fileName = '${const Uuid().v4()}${path.extension(imageFile.value!.path)}';
      final storageRef = _storage.ref().child('articles').child(fileName);

      await storageRef.putFile(imageFile.value!);
      final downloadUrl = await storageRef.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      Get.snackbar(
        'error'.tr,
        'error_uploading_image'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  // Сохранение статьи
  Future<void> saveArticle() async {
    // Валидация полей
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        contentController.text.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'fill_required_fields'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;

    try {
      // Загрузка изображения
      String? uploadedImageUrl;
      if (imageFile.value != null) {
        uploadedImageUrl = await _uploadImage();
        if (uploadedImageUrl == null) {
          isLoading.value = false;
          return;
        }
      }

      // Создаем модель статьи с учетом видимости
      final articleModel = ArticleModel(
        id: article?.id ?? const Uuid().v4(),
        title: titleController.text,
        description: descriptionController.text,
        content: contentController.text,
        imageUrl: uploadedImageUrl ?? imageUrl.value,
        publishedAt: article?.publishedAt ?? DateTime.now(),
        authorName: authorNameController.text,
        authorAvatarUrl: defaultAuthorAvatarUrl, // Используем фиксированный URL
        type: selectedType.value,
        isVisible: isVisible.value, // Используем выбранное значение видимости
      );

      // Конвертируем в Map для Firestore
      final articleData = articleModel.toFirestore();

      if (article == null) {
        // Создание новой статьи
        await _firestore.collection('articles').add(articleData);

        Get.snackbar(
          'success'.tr,
          'article_created'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        // Обновление существующей статьи
        await _firestore.collection('articles').doc(article!.id).update(articleData);

        Get.snackbar(
          'success'.tr,
          'article_updated'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      // Вызов колбэка при успешном сохранении
      if (onSave != null) {
        onSave!();
      }

      Get.back();
    } catch (e) {
      debugPrint('Error saving article: $e');
      Get.snackbar(
        'error'.tr,
        'error_saving_article'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}

class ArticleEditDirectScreen extends StatelessWidget {
  final Article? article;
  final String? articleType;
  final Function? onSave;

  ArticleEditDirectScreen({
    Key? key,
    this.article,
    this.articleType,
    this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ArticleEditDirectController(
      article: article,
      articleType: articleType,
      onSave: onSave,
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(article == null ? 'create_article'.tr : 'edit_article'.tr),
        actions: [
          // Save button or loading indicator
          Obx(() => controller.isLoading.value
              ? Container(
            margin: const EdgeInsets.all(16),
            width: 24,
            height: 24,
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
              : IconButton(
            icon: const Icon(Icons.save),
            onPressed: controller.saveArticle,
          ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение
            _buildImageSection(context, controller),
            const SizedBox(height: 24),

            // Выбор типа статьи
            Text(
              'article_type'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildArticleTypeSelector(controller),
            const SizedBox(height: 24),

            // Visibility toggle option
            Row(
              children: [
                Text(
                  'visibility'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Obx(() => Switch(
                  value: controller.isVisible.value,
                  onChanged: (value) {
                    controller.isVisible.value = value;
                  },
                  activeColor: Colors.green,
                )),
                Text(
                  controller.isVisible.value ? 'visible'.tr : 'hidden'.tr,
                  style: TextStyle(
                    color: controller.isVisible.value ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Основные поля
            _buildTextField(
              controller: controller.titleController,
              label: 'title'.tr,
              hint: 'article_title_hint'.tr,
              isRequired: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: controller.descriptionController,
              label: 'description'.tr,
              hint: 'article_description_hint'.tr,
              isRequired: true,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: controller.contentController,
              label: 'content'.tr,
              hint: 'article_content_hint'.tr,
              isRequired: true,
              maxLines: 15,
            ),
            const SizedBox(height: 16),

            // Информация об авторе
            Text(
              'author_information'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            _buildTextField(
              controller: controller.authorNameController,
              label: 'author_name'.tr,
              hint: 'author_name_hint'.tr,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleTypeSelector(ArticleEditDirectController controller) {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: controller.selectedType.value,
          items: controller.articleTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type['value'],
              child: Text(type['label']!.tr),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              controller.selectedType.value = value;
            }
          },
        ),
      ),
    ));
  }

  Widget _buildImageSection(BuildContext context, ArticleEditDirectController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'article_image'.tr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.imageFile.value != null) {
            // Отображение выбранного изображения
            return AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      controller.imageFile.value!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton.small(
                      onPressed: () => controller.imageFile.value = null,
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.close, color: Colors.black),
                    ),
                  ),
                ],
              ),
            );
          } else if (controller.imageUrl.value.isNotEmpty) {
            // Отображение существующего изображения
            return AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: controller.imageUrl.value,
                      width: double.infinity,
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
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton.small(
                      onPressed: controller.pickImage,
                      child: const Icon(Icons.edit),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Кнопка выбора изображения
            return InkWell(
              onTap: controller.pickImage,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                height: 200,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'tap_to_select_image'.tr,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
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
}