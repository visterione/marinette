import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/services/face_analysis_service.dart';
import 'package:marinette/app/data/services/result_saver_service.dart';
import 'package:marinette/app/data/services/content_service.dart';
import 'package:marinette/config/translations/app_translations.dart';
import 'package:marinette/app/modules/analysis/analysis_result_screen.dart';
import 'package:marinette/app/modules/beauty_hub/beauty_hub_screen.dart';
import 'package:marinette/app/modules/camera/camera_controller.dart';
import 'package:marinette/app/modules/history/history_screen.dart';
import 'package:marinette/app/core/widgets/wave_background_painter.dart';
import 'package:marinette/app/data/models/story.dart';
import 'package:marinette/app/data/services/stories_service.dart';
import 'package:marinette/app/core/widgets/story_viewer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RxList<Story> _stories = <Story>[].obs;

  void _changeLanguage() {
    final service = Get.find<LocalizationService>();
    final newLocale = service.getCurrentLocale() == 'en' ? 'uk' : 'en';
    service.changeLocale(newLocale);
  }

  Future<void> _processImage(String? imagePath) async {
    if (imagePath != null) {
      try {
        debugPrint('Starting image processing for path: $imagePath');

        Get.dialog(
          PopScope(
            canPop: false,
            child: const Center(child: CircularProgressIndicator()),
          ),
          barrierDismissible: false,
        );

        final analysisService = Get.put(FaceAnalysisService());
        final result = await analysisService.analyzeFace(imagePath);

        if (Get.isDialogOpen ?? false) {
          Get.back();
        }

        if (result != null) {
          debugPrint('Saving result to history');
          try {
            final resultSaverService = Get.find<ResultSaverService>();
            await resultSaverService.saveResult(
              imagePath: imagePath,
              result: result,
            );
            debugPrint('Result saved successfully');
          } catch (e) {
            debugPrint('Error saving result: $e');
            Get.snackbar(
              'error'.tr,
              'error_saving_result'.tr,
              snackPosition: SnackPosition.BOTTOM,
            );
          }

          await Get.to(() => AnalysisResultScreen(
                imagePath: imagePath,
                result: result,
              ));
        } else {
          Get.snackbar(
            'error'.tr,
            'analysis_failed'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } catch (e) {
        debugPrint('Error during image processing: $e');
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
        Get.snackbar(
          'error'.tr,
          'analysis_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      final stories = await StoriesService.getStories();
      _stories.value = stories;
    } catch (e) {
      debugPrint('Error loading stories: $e');
      Get.snackbar(
        'error'.tr,
        'error_loading_stories'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _handleStoryTap(Story story) {
    Get.to(
      () => StoryViewer(
        story: story,
        onClose: () => Get.back(),
      ),
      fullscreenDialog: true,
      transition: Transition.fadeIn,
    );
  }

  Widget _buildStoriesSection() {
    return Obx(() {
      if (_stories.isEmpty) return const SizedBox.shrink();

      return Container(
        height: 85, // Зменшена загальна висота
        margin: const EdgeInsets.only(bottom: 24),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _stories.length,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemBuilder: (context, index) {
            final story = _stories[index];
            return GestureDetector(
              onTap: () => _handleStoryTap(story),
              child: Container(
                width: 60, // Зменшена ширина
                margin: const EdgeInsets.only(right: 8), // Зменшений відступ
                child: Column(
                  children: [
                    Container(
                      height: 60, // Зменшена висота кружечка
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: story.isViewed
                            ? null
                            : const LinearGradient(
                                colors: [Colors.pink, Colors.purple],
                              ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(story.previewImageUrl),
                            fit: BoxFit.cover,
                          ),
                          border: story.isViewed
                              ? Border.all(color: Colors.grey.shade300)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      story.title,
                      style: const TextStyle(
                        fontSize: 11, // Зменшений розмір шрифту
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildFeatureCard({
    required String titleKey,
    required String subtitleKey,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 8,
      shadowColor: Colors.pink.withAlpha(76),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleKey.tr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitleKey.tr,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.pink.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Colors.pink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipOfTheDay(ContentService contentService) {
    return Obx(() {
      final tip = contentService.currentTip.value;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.pink, Colors.purple],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withAlpha(76),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  tip.icon,
                  style: const TextStyle(
                    fontSize: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'tip_of_the_day'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tip.tip.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTrendsCarousel(ContentService contentService) {
    return Obx(() {
      final trends = contentService.currentTrends;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: Colors.pink,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'season_trends'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: trends
                  .map((trend) => Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _buildTrendCard(
                          title: trend.title.tr,
                          description:
                              '${trend.title.toLowerCase()}_description'.tr,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTrendCard({required String title, required String description}) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ініціалізуємо CustomCameraController
    final cameraController = Get.put(CustomCameraController());

    final contentService = Get.find<ContentService>();
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('app_name'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Get.to(() => HistoryScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _changeLanguage,
          ),
        ],
      ),
      body: Container(
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDF2F8), Color(0xFFF5F3FF)],
            stops: [0.0, 1.0],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: WaveBackgroundPainter(),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStoriesSection(),
                      _buildFeatureCard(
                        titleKey: 'take_photo',
                        subtitleKey: 'take_photo_subtitle',
                        icon: Icons.camera_alt,
                        onTap: () async {
                          final imagePath = await cameraController.takePhoto();
                          await _processImage(imagePath);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        titleKey: 'choose_from_gallery',
                        subtitleKey: 'choose_from_gallery_subtitle',
                        icon: Icons.photo_library,
                        onTap: () async {
                          final imagePath =
                              await cameraController.pickFromGallery();
                          await _processImage(imagePath);
                        },
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          Get.to(() => const BeautyHubScreen());
                        },
                        child: _buildFeatureCard(
                          titleKey: 'beauty_hub',
                          subtitleKey: 'beauty_hub_subtitle',
                          icon: Icons.menu_book,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTipOfTheDay(contentService),
                      const SizedBox(height: 24),
                      _buildTrendsCarousel(contentService),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
