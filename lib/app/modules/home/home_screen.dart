// lib/app/modules/home/home_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/story.dart';
import 'package:marinette/app/data/services/auth_service.dart';
import 'package:marinette/app/data/services/content_service.dart';
import 'package:marinette/app/data/services/face_analysis_service.dart';
import 'package:marinette/app/data/services/result_saver_service.dart';
import 'package:marinette/app/data/services/stories_service.dart';
import 'package:marinette/app/modules/analysis/analysis_result_screen.dart';
import 'package:marinette/app/modules/beauty_hub/beauty_hub_screen.dart';
import 'package:marinette/app/modules/camera/camera_controller.dart';
import 'package:marinette/app/core/widgets/wave_background_painter.dart';
import 'package:marinette/app/core/widgets/story_viewer.dart';
import 'package:marinette/app/core/widgets/stories_section.dart';
import 'package:marinette/app/modules/auth/auth_screen.dart';
import 'package:marinette/app/modules/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _authService = Get.find<AuthService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleStoryTap(Story story) {
    final storiesService = Get.find<StoriesService>();
    final storyIndex = storiesService.stories.indexOf(story);

    Get.to(
          () => StoryViewer(
        story: story,
        onClose: () => Get.back(),
        storyIndex: storyIndex,
      ),
      fullscreenDialog: true,
      transition: Transition.fadeIn,
    );
  }

  // Метод обробки зображення для аналізу
  Future<void> _processImage(String? imagePath) async {
    if (imagePath != null) {
      try {
        debugPrint('Starting image processing for path: $imagePath');
        final analysisService = Get.put(FaceAnalysisService());

        // Показуємо індикатор завантаження
        Get.dialog(
          PopScope(
            canPop: false,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
            ),
          ),
          barrierDismissible: false,
        );

        // Встановлюємо таймаут на аналіз обличчя
        final result = await analysisService.analyzeFace(imagePath)
            .timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Face analysis took too long'),
        );

        // Закриваємо діалог завантаження
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

            await Get.to(() => AnalysisResultScreen(
              imagePath: imagePath,
              result: result,
            ));
          } catch (e) {
            debugPrint('Error saving result: $e');
            Get.snackbar(
              'error'.tr,
              'error_saving_result'.tr,
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        } else {
          Get.snackbar(
            'error'.tr,
            'error_no_face'.tr,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
      } on TimeoutException catch (_) {
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
        Get.snackbar(
          'error'.tr,
          'error_analysis_timeout'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        debugPrint('Error during image processing: $e');
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
        Get.snackbar(
          'error'.tr,
          'error_analyzing'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  Widget _buildStoriesSection() {
    final storiesService = Get.find<StoriesService>();

    return Obx(() {
      final stories = storiesService.stories;
      if (stories.isEmpty) return const SizedBox.shrink();

      return StoriesSection(
        stories: stories,
        onStoryTap: _handleStoryTap,
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
            color: Theme.of(context).cardColor,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleKey.tr,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitleKey.tr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                        Theme.of(context).brightness == Brightness.light
                            ? Colors.grey[600]
                            : Colors.grey[300],
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
                  title: trend.title,
                  description: trend.description,
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
        color: Theme.of(context).cardColor,
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
            title.tr,  // Используем .tr здесь для перевода
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description.tr,  // Используем .tr здесь для перевода
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
    final cameraController = Get.put(CustomCameraController());
    final contentService = Get.find<ContentService>();
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('app_name'.tr),
        leading: Obx(() {
          if (_authService.isLoggedIn) {
            return GestureDetector(
              onTap: () {
                Get.to(() => ProfileScreen());
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _authService.userModel?.photoUrl != null
                    ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: _authService.userModel!.photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(Icons.person),
                  ),
                )
                    : Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          } else {
            return IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                Get.to(() => AuthScreen());
              },
            );
          }
        }),
      ),
      body: Container(
        height: screenHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFFDF2F8)
                  : const Color(0xFF1A1A1A),
              Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFF5F3FF)
                  : const Color(0xFF262626),
            ],
            stops: const [0.0, 1.0],
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStoriesSection(),
                      const SizedBox(height: 20), // Increased spacing

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

                      const SizedBox(height: 20), // Increased spacing

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

                      const SizedBox(height: 28), // Further increased spacing

                      _buildTipOfTheDay(contentService),

                      const SizedBox(height: 28), // Further increased spacing

                      _buildTrendsCarousel(contentService),

                      // Bottom padding to ensure there's no empty space
                      SizedBox(height: MediaQuery.of(context).size.height * 0.05),
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