import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/core/theme/theme_service.dart';
import 'package:marinette/app/data/models/story.dart';
import 'package:marinette/app/data/services/background_music_handler.dart';
import 'package:marinette/app/data/services/content_service.dart';
import 'package:marinette/app/data/services/face_analysis_service.dart';
import 'package:marinette/app/data/services/localization_service.dart';
import 'package:marinette/app/data/services/result_saver_service.dart';
import 'package:marinette/app/data/services/stories_service.dart';
import 'package:marinette/app/modules/analysis/analysis_result_screen.dart';
import 'package:marinette/app/modules/beauty_hub/beauty_hub_screen.dart';
import 'package:marinette/app/modules/camera/camera_controller.dart';
import 'package:marinette/app/modules/history/history_screen.dart';
import 'package:marinette/app/core/widgets/wave_background_painter.dart';
import 'package:marinette/app/core/widgets/story_viewer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _musicHandler = BackgroundMusicHandler.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startBackgroundMusic();
  }

  @override
  void dispose() {
    _musicHandler.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _musicHandler.stop();
        break;
      case AppLifecycleState.resumed:
        _musicHandler.play();
        break;
    }
  }

  Future<void> _startBackgroundMusic() async {
    await _musicHandler.play();
  }

  void _changeLanguage() {
    final service = Get.find<LocalizationService>();
    final currentLocale = service.getCurrentLocale().languageCode;

    String newLocale;
    switch (currentLocale) {
      case 'uk':
        newLocale = 'en';
      case 'en':
        newLocale = 'pl';
      case 'pl':
        newLocale = 'ka';
      case 'ka':
        newLocale = 'uk';
      default:
        newLocale = 'uk';
    }

    service.changeLocale(newLocale);
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

  Widget _buildStoriesSection() {
    final storiesService = Get.find<StoriesService>();

    return Obx(() {
      final stories = storiesService.stories;
      if (stories.isEmpty) return const SizedBox.shrink();

      return Container(
        height: 85,
        margin: const EdgeInsets.only(bottom: 24),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: stories.length,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemBuilder: (context, index) {
            final story = stories[index];
            return GestureDetector(
              onTap: () => _handleStoryTap(story),
              child: Container(
                width: 60,
                margin: const EdgeInsets.only(right: 8),
                child: Column(
                  children: [
                    Container(
                      height: 60,
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
                            image: NetworkImage(story.previewImageUrl.tr),
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
                      story.title.tr,
                      style: const TextStyle(
                        fontSize: 11,
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
    final cameraController = Get.put(CustomCameraController());
    final contentService = Get.find<ContentService>();
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
        appBar: AppBar(
        title: Text('app_name'.tr),
    actions: [
    PopupMenuButton<String>(
    icon: const Icon(Icons.more_vert),
    itemBuilder: (context) => [
    PopupMenuItem<String>(
    value: 'theme',
    child: Row(
    children: [
    Obx(() {
    final themeService = Get.find<ThemeService>();
    return Icon(
    themeService.isDarkMode
    ? Icons.light_mode
        : Icons.dark_mode,
    size: 20,
    color: Colors.pink,
    );
    }),
    const SizedBox(width: 12),
    Text('theme'.tr),
    ],
    ),
    ),
    PopupMenuItem<String>(
    value: 'sound',
    child: Row(
    children: [
    const Icon(
    Icons.volume_up,
    size: 20,
    color: Colors.pink,
    ),
    const SizedBox(width: 12),
    Text(_musicHandler.isMuted ? 'unmute'.tr : 'mute'.tr),
    ],
    ),
    ),
    PopupMenuItem<String>(
    value: 'history',
    child: Row(
    children: [
    const Icon(Icons.history, size: 20, color: Colors.pink),
    const SizedBox(width: 12),
    Text('history'.tr),
    ],
    ),
    ),
    PopupMenuItem<String>(
    value: 'language',
    child: Row(
    children: [
    const Icon(Icons.language, size: 20, color: Colors.pink),
    const SizedBox(width: 12),
    Text('language'.tr),
    ],
    ),
    ),
    ],
    onSelected: (value) {
    switch (value) {
    case 'theme':
    final themeService = Get.find<ThemeService>();
    themeService.toggleTheme();
    case 'sound':
    _musicHandler.toggleMute();
    case 'history':
    Get.to(() => HistoryScreen());
    case 'language':
    _changeLanguage();
    }
    },
    ),
    ],
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