import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:marinette/app/data/models/story.dart';
import 'package:marinette/app/data/services/stories_service.dart';

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

class _StoryViewerState extends State<StoryViewer> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  final StoriesService _storiesService = Get.find<StoriesService>();

  int currentIndex = 0;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _animationController.addStatusListener(_onAnimationStatus);
    _startAnimation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _animationController.forward();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (currentIndex < widget.story.imageUrls.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _storiesService.markStoryAsViewed(widget.story.id);
        widget.onClose();
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
    _animationController.reset();
    _startAnimation();

    if (index == widget.story.imageUrls.length - 1) {
      _storiesService.markStoryAsViewed(widget.story.id);
    }
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
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < screenWidth / 2) {
            // Клік на ліву частину екрану
            if (currentIndex > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          } else {
            // Клік на праву частину екрану
            if (currentIndex < widget.story.imageUrls.length - 1) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              _storiesService.markStoryAsViewed(widget.story.id);
              widget.onClose();
            }
          }
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.story.imageUrls.length,
              onPageChanged: _onPageChanged,
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
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
              child: Column(
                children: [
                  Row(
                    children: List.generate(
                      widget.story.imageUrls.length,
                          (index) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: LinearProgressIndicator(
                            value: index == currentIndex
                                ? _animationController.value
                                : index < currentIndex
                                ? 1.0
                                : 0.0,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(widget.story.previewImageUrl.tr),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.story.title.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
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
                            onPressed: () {
                              _animationController.stop();
                              widget.onClose();
                            },
                          ),
                        ],
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