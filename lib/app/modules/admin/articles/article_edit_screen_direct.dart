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
  });

  // Создаем ключи на основе ID или UUID
  String get titleKey => 'content_${id}_title';
  String get descriptionKey => 'content_${id}_desc';
  String get contentKey => 'content_${id}_full';
  String get authorNameKey => 'author_${authorName.toLowerCase().replaceAll(' ', '_')}';

  // Преобразование ArticleModel в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'titleKey': titleKey,
      'descriptionKey': descriptionKey,
      'contentKey': contentKey,
      'imageUrl': imageUrl,
      'authorNameKey': authorNameKey,
      'authorAvatarUrl': authorAvatarUrl,
      'type': type,
      'publishedAt': publishedAt,
      'title': title,
      'description': description,
      'content': content,
      'authorName': authorName,
    };
  }

  // Создание модели из Article
  factory ArticleModel.fromArticle(Article article, {String type = 'article'}) {
    return ArticleModel(
      id: article.id,
      title: article.titleKey.tr,
      description: article.descriptionKey.tr,
      content: article.contentKey.tr,
      imageUrl: article.imageUrl,
      publishedAt: article.publishedAt,
      authorName: article.authorNameKey.tr,
      authorAvatarUrl: article.authorAvatarUrl,
      type: type,
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
  late TextEditingController authorAvatarUrlController;

  // Реактивные переменные
  final RxBool isLoading = false.obs;
  final RxString imageUrl = ''.obs;
  final Rxn<File> imageFile = Rxn<File>();

  ArticleEditDirectController({
    this.article,
    this.articleType,
    this.onSave,
  });

  @override
  void onInit() {
    super.onInit();

    // Инициализация контроллеров
    titleController = TextEditingController(text: article != null ? article!.titleKey.tr : '');
    descriptionController = TextEditingController(text: article != null ? article!.descriptionKey.tr : '');
    contentController = TextEditingController(text: article != null ? article!.contentKey.tr : '');
    authorNameController = TextEditingController(text: article != null ? article!.authorNameKey.tr : 'Admin');
    authorAvatarUrlController = TextEditingController(text: article?.authorAvatarUrl ?? 'https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.appspot.com/o/authors%2Fdefault_avatar.jpg?alt=media');

    if (article != null) {
      imageUrl.value = article!.imageUrl;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    contentController.dispose();
    authorNameController.dispose();
    authorAvatarUrlController.dispose();
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

      // Создаем модель статьи
      final articleModel = ArticleModel(
        id: article?.id ?? const Uuid().v4(),
        title: titleController.text,
        description: descriptionController.text,
        content: contentController.text,
        imageUrl: uploadedImageUrl ?? imageUrl.value,
        publishedAt: article?.publishedAt ?? DateTime.now(),
        authorName: authorNameController.text,
        authorAvatarUrl: authorAvatarUrlController.text,
        type: articleType ?? article?.titleKey.split('_')[0] ?? 'article',
      );

      // Конвертируем в Map для Firestore
      final articleData = articleModel.toFirestore();

      if (article == null) {
        // Создание новой статьи
        await _firestore.collection('articles').add(articleData);

        // Добавляем переводы в коллекцию translations
        await _addTranslations(articleModel);

        Get.snackbar(
          'success'.tr,
          'article_created'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        // Обновление существующей статьи
        await _firestore.collection('articles').doc(article!.id).update(articleData);

        // Обновляем переводы
        await _addTranslations(articleModel);

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

  // Добавление переводов в коллекцию translations
  Future<void> _addTranslations(ArticleModel model) async {
    try {
      // Создаем или обновляем переводы для английского языка
      await _firestore.collection('translations').doc('en').set({
        model.titleKey: model.title,
        model.descriptionKey: model.description,
        model.contentKey: model.content,
        model.authorNameKey: model.authorName,
      }, SetOptions(merge: true));

      // Создаем или обновляем те же переводы для украинского языка
      // В реальном приложении здесь могла бы быть отдельная форма для украинского перевода
      await _firestore.collection('translations').doc('uk').set({
        model.titleKey: model.title,
        model.descriptionKey: model.description,
        model.contentKey: model.content,
        model.authorNameKey: model.authorName,
      }, SetOptions(merge: true));

    } catch (e) {
      debugPrint('Error adding translations: $e');
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
            const SizedBox(height: 16),

            _buildTextField(
              controller: controller.authorAvatarUrlController,
              label: 'author_avatar_url'.tr,
              hint: 'author_avatar_url_hint'.tr,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
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