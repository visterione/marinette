import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marinette/app/data/services/storage_service.dart';

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({Key? key}) : super(key: key);

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final StorageService _storageService = Get.find<StorageService>();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _pathController = TextEditingController();

  File? _selectedImage;
  String? _uploadedUrl;
  bool _isUploading = false;

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _uploadedUrl = null;
        });
      }
    } catch (e) {
      debugPrint('Ошибка выбора изображения: $e');
      Get.snackbar(
        'Ошибка',
        'Не удалось выбрать изображение: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      Get.snackbar(
        'Ошибка',
        'Сначала выберите изображение',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_pathController.text.trim().isEmpty) {
      Get.snackbar(
        'Ошибка',
        'Укажите путь для загрузки',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final path = _pathController.text.trim();
      final url = await _storageService.uploadFile(_selectedImage!, path);

      setState(() {
        _uploadedUrl = url;
        _isUploading = false;
      });

      if (url != null) {
        Get.snackbar(
          'Успех',
          'Изображение успешно загружено',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Ошибка',
          'Не удалось загрузить изображение',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      Get.snackbar(
        'Ошибка',
        'Ошибка загрузки: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _copyUrlToClipboard() async {
    if (_uploadedUrl != null) {
      await Clipboard.setData(ClipboardData(text: _uploadedUrl!));
      Get.snackbar(
        'Скопировано',
        'URL скопирован в буфер обмена',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Загрузка изображений'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Загрузка изображений в Firebase Storage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Выбор изображения
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
              )
                  : Center(
                child: IconButton(
                  icon: const Icon(Icons.add_photo_alternate, size: 50),
                  onPressed: _pickImage,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Кнопка выбора изображения
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Выбрать изображение'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // Путь для загрузки
            TextField(
              controller: _pathController,
              decoration: InputDecoration(
                labelText: 'Путь в Firebase Storage',
                hintText: 'articles/my_article.jpg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.folder),
              ),
            ),
            const SizedBox(height: 8),

            // Подсказки для путей
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                    _pathController.text = 'articles/article_$timestamp.jpg';
                  },
                  child: const Text('Статья'),
                ),
                TextButton(
                  onPressed: () {
                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                    _pathController.text = 'stories/$timestamp/preview.jpg';
                  },
                  child: const Text('Превью истории'),
                ),
                TextButton(
                  onPressed: () {
                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                    _pathController.text = 'stories/$timestamp/00.jpg';
                  },
                  child: const Text('Изображение истории'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Кнопка загрузки
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey,
              ),
              child: _isUploading
                  ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Загрузка...'),
                ],
              )
                  : const Text('Загрузить изображение'),
            ),
            const SizedBox(height: 24),

            // Отображение URL загруженного изображения
            if (_uploadedUrl != null) ...[
              const Text(
                'URL загруженного изображения:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _uploadedUrl!,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: _copyUrlToClipboard,
                      tooltip: 'Копировать URL',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Get.back(result: _uploadedUrl);
                },
                child: const Text('Использовать этот URL и вернуться'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}