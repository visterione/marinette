import 'dart:io';
import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:marinette/app/data/models/story.dart';
import 'package:marinette/app/data/services/stories_service.dart';

class StoryViewer extends StatefulWidget {
  final Story story;
  final VoidCallback onClose;
  final int storyIndex;

  const StoryViewer({
    super.key,
    required this.story,
    required this.onClose,
    required this.storyIndex,
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
  bool _isImageLoading = true;
  final RxBool _isInitialLoadComplete = false.obs;

  // Constants for customizing story timing
  final Duration _storyDuration = const Duration(seconds: 5);
  final Duration _storyTransitionDuration = const Duration(milliseconds: 300);
  final Curve _storyTransitionCurve = Curves.easeInOut;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    );
    _animationController.addStatusListener(_onAnimationStatus);
    _prepareImages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _prepareImages() async {
    setState(() => _isImageLoading = true);

    final firstImage = widget.story.imageUrls[0].tr;
    if (!_storiesService.isImagePreloaded(firstImage)) {
      await _waitForImage(firstImage);
    }

    _preloadRemainingImages();

    setState(() {
      _isImageLoading = false;
      _isInitialLoadComplete.value = true;
    });
    _startAnimation();
  }

  Future<void> _waitForImage(String imageUrl) async {
    int attempts = 0;
    while (!_storiesService.isImagePreloaded(imageUrl) && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }

  void _preloadRemainingImages() async {
    for (var i = currentIndex + 1; i < widget.story.imageUrls.length; i++) {
      final imageUrl = widget.story.imageUrls[i].tr;
      if (!_storiesService.isImagePreloaded(imageUrl)) {
        await _storiesService.preloadSingleImage(imageUrl, priority: true);
      }
    }

    _storiesService.preloadNextStoryImages(widget.storyIndex);
  }

  void _startAnimation() {
    if (!_isImageLoading && mounted) {
      _animationController.forward(from: 0.0);
    }
  }

  void _pauseAnimation() {
    _animationController.stop();
  }

  void _resumeAnimation() {
    _animationController.forward();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (currentIndex < widget.story.imageUrls.length - 1) {
        _goToNextPage();
      } else {
        _storiesService.markStoryAsViewed(widget.story.id);
        widget.onClose();
      }
    }
  }

  void _goToNextPage() {
    _pageController.nextPage(
      duration: _storyTransitionDuration,
      curve: _storyTransitionCurve,
    );
  }

  void _goToPreviousPage() {
    _pageController.previousPage(
      duration: _storyTransitionDuration,
      curve: _storyTransitionCurve,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
    _animationController.reset();
    _checkCurrentImageStatus();
  }

  void _checkCurrentImageStatus() {
    final currentImageUrl = widget.story.imageUrls[currentIndex].tr;

    setState(() {
      _isImageLoading = !_storiesService.isImagePreloaded(currentImageUrl);
    });

    if (!_isImageLoading) {
      _startAnimation();
    }
  }

  Future<void> _shareCurrentImage() async {
    if (_isSharing) return;

    // Pause animation while sharing
    _pauseAnimation();

    setState(() {
      _isSharing = true;
    });

    http.Client? client;
    File? tempFile;

    try {
      // Local copy of URL
      final String imageUrl = widget.story.imageUrls[currentIndex].tr;
      debugPrint('Starting image download: $imageUrl');

      // Create HTTP client
      client = http.Client();

      // Download image data
      final response = await client.get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Download error: ${response.statusCode}');
      }

      // Get available directory
      final tempDir = await getTemporaryDirectory();
      if (tempDir == null) {
        throw Exception('Could not get temporary directory');
      }

      // Check that directory exists
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }

      // Create unique filename
      final tempFileName = 'share_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFilePath = '${tempDir.path}/$tempFileName';

      // Create and write file
      tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(response.bodyBytes);

      // Additional check for file existence
      if (!await tempFile.exists() || await tempFile.length() == 0) {
        throw Exception('Could not create temporary file or file is empty');
      }

      // Prepare data for Share
      String? shareText;
      if (widget.story.captions.isNotEmpty && currentIndex < widget.story.captions.length) {
        shareText = widget.story.captions[currentIndex].tr;
      }

      // Share file
      final xFile = XFile(tempFilePath);
      await Share.shareXFiles(
        [xFile],
        text: shareText,
      );

      debugPrint('Image shared successfully');
    } catch (e) {
      debugPrint('Error while trying to share: $e');
      Get.snackbar(
        'error'.tr,
        'error_sharing'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      // Free resources
      if (client != null) {
        client.close();
      }

      // Delete temporary file if it was created
      try {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        debugPrint('Error deleting temporary file: $e');
      }

      if (mounted) {
        setState(() {
          _isSharing = false;
        });
        // Resume animation after sharing
        _resumeAnimation();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitialLoadComplete.value
          ? _buildStoryView()
          : const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildStoryView() {
    return GestureDetector(
      onTapDown: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        // Pause animation on tap
        _pauseAnimation();

        if (details.localPosition.dx < screenWidth / 2) {
          if (currentIndex > 0) {
            _goToPreviousPage();
          }
        } else {
          if (currentIndex < widget.story.imageUrls.length - 1) {
            _goToNextPage();
          } else {
            _storiesService.markStoryAsViewed(widget.story.id);
            widget.onClose();
          }
        }
      },
      onTapUp: (_) {
        // Resume animation on tap release
        _resumeAnimation();
      },
      onLongPressStart: (_) {
        // Pause animation on long press
        _pauseAnimation();
      },
      onLongPressEnd: (_) {
        // Resume animation when long press ends
        _resumeAnimation();
      },
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.story.imageUrls.length,
            onPageChanged: _onPageChanged,
            physics: const NeverScrollableScrollPhysics(), // Disable manual scrolling
            itemBuilder: (context, index) {
              final imageUrl = widget.story.imageUrls[index].tr;
              return Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.black,
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                  if (widget.story.captions.length > index)
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
                // Improved progress indicators
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: List.generate(
                      widget.story.imageUrls.length,
                          (index) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(2.0),
                                child: LinearProgressIndicator(
                                  value: index == currentIndex
                                      ? _isImageLoading ? 0 : _animationController.value
                                      : index < currentIndex
                                      ? 1.0
                                      : 0.0,
                                  backgroundColor: Colors.white.withOpacity(0.3),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  minHeight: 3, // Slightly thicker for better visibility
                                ),
                              );
                            },
                          ),
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
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: widget.story.previewImageUrl.tr,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
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
                    // Only the close button
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
          ),
        ],
      ),
    );
  }
}