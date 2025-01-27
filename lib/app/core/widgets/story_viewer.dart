import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/story.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class StoryViewer extends StatefulWidget {
  final Story story;
  final VoidCallback onClose;

  const StoryViewer({
    super.key,
    required this.story,
    required this.onClose,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  int currentIndex = 0;
  late PageController _pageController;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _shareCurrentImage() async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final imageUrl = widget.story.imageUrls[currentIndex].tr;

      // Завантажуємо зображення
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // Зберігаємо зображення тимчасово
      final tempDir = await getTemporaryDirectory();
      final tempImagePath = '${tempDir.path}/share_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(tempImagePath).writeAsBytes(response.bodyBytes);

      // Ділимося зображенням
      await Share.shareXFiles(
        [XFile(tempImagePath)],
        text: widget.story.captions[currentIndex].tr,
      );

      // Видаляємо тимчасовий файл
      await File(tempImagePath).delete();
    } catch (e) {
      debugPrint('Error sharing image: $e');
      Get.snackbar(
        'error'.tr,
        'error_sharing'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() {
        _isSharing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.story.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.story.imageUrls[index].tr,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: Text(
                      widget.story.captions[index].tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: Row(
              children: [
                ...List.generate(
                  widget.story.imageUrls.length,
                      (index) => Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      color: index <= currentIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: Row(
              children: [
                if (!_isSharing)
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: _shareCurrentImage,
                  )
                else
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}