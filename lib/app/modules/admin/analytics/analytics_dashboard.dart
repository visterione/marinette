// lib/app/modules/admin/analytics/analytics_dashboard.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxBool isLoading = false.obs;

  // User statistics
  final RxInt totalUsers = 0.obs;

  // User preferences statistics
  final RxMap<String, int> ageDistribution = <String, int>{}.obs;
  final RxMap<String, int> skinTypeDistribution = <String, int>{}.obs;

  // Content statistics
  final RxInt totalArticles = 0.obs;
  final RxInt totalStories = 0.obs;
  final RxInt totalAnalyses = 0.obs;

  // Engagement statistics
  final RxInt totalArticleViews = 0.obs;
  final RxInt totalStoryViews = 0.obs;
  final RxMap<String, int> articleViewsByCategory = <String, int>{}.obs;
  final RxMap<String, int> storyViewsByCategory = <String, int>{}.obs;

  // Face analysis statistics
  final RxMap<String, int> faceShapeDistribution = <String, int>{}.obs;
  final RxMap<String, int> colorTypeDistribution = <String, int>{}.obs;

  // Selected time period
  final Rx<TimeFilter> selectedTimeFilter = TimeFilter.last30Days.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAnalyticsData();
  }

  Future<void> fetchAnalyticsData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _fetchUserStatistics(),
        _fetchContentStatistics(),
        _fetchEngagementStatistics(),
        _fetchUserPreferencesStatistics(),
        _fetchFaceAnalysisStatistics(),
      ]);
    } catch (e) {
      debugPrint('Error fetching analytics data: $e');
      Get.snackbar(
        'error'.tr,
        'error_loading_analytics'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // User statistics
  Future<void> _fetchUserStatistics() async {
    // Get total users
    final usersSnapshot = await _firestore.collection('users').get();
    totalUsers.value = usersSnapshot.size;
  }

  // User preferences statistics
  Future<void> _fetchUserPreferencesStatistics() async {
    final usersSnapshot = await _firestore.collection('users').get();

    Map<String, int> ages = {};
    Map<String, int> skinTypes = {};

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      if (data.containsKey('preferences')) {
        final preferences = data['preferences'] as Map<String, dynamic>?;

        // Age distribution
        if (preferences != null && preferences.containsKey('age')) {
          final age = preferences['age'] as int?;
          if (age != null) {
            String ageGroup;
            if (age < 18) {
              ageGroup = 'under_18'.tr;
            } else if (age < 25) {
              ageGroup = '18_24'.tr;
            } else if (age < 35) {
              ageGroup = '25_34'.tr;
            } else if (age < 45) {
              ageGroup = '35_44'.tr;
            } else if (age < 55) {
              ageGroup = '45_54'.tr;
            } else {
              ageGroup = '55_plus'.tr;
            }
            ages[ageGroup] = (ages[ageGroup] ?? 0) + 1;
          }
        }

        // Skin type distribution
        if (preferences != null && preferences.containsKey('skinType')) {
          final skinType = preferences['skinType'] as String?;
          if (skinType != null) {
            String skinTypeKey = 'skin_type_${skinType}'.tr;
            skinTypes[skinTypeKey] = (skinTypes[skinTypeKey] ?? 0) + 1;
          }
        }
      }
    }

    ageDistribution.value = ages;
    skinTypeDistribution.value = skinTypes;
  }

  // Content statistics
  Future<void> _fetchContentStatistics() async {
    // Get article count
    final articlesSnapshot = await _firestore.collection('articles').get();
    totalArticles.value = articlesSnapshot.size;

    // Get story count
    final storiesSnapshot = await _firestore.collection('stories').get();
    totalStories.value = storiesSnapshot.size;

    // Get total analyses count
    final analysesSnapshot = await _firestore.collection('user_analysis').get();
    totalAnalyses.value = analysesSnapshot.size;
  }

  // Engagement statistics
  Future<void> _fetchEngagementStatistics() async {
    // In a real app, you would have a proper analytics collection
    // Here we're simulating with limited data

    // For article views by category
    final articleViewsSnapshot = await _firestore
        .collection('article_views')
        .get();

    Map<String, int> categoryViews = {};
    for (var doc in articleViewsSnapshot.docs) {
      final data = doc.data();
      final category = data['category'] as String? ?? 'unknown';
      categoryViews[category] = (categoryViews[category] ?? 0) + 1;
    }

    articleViewsByCategory.value = categoryViews;
    totalArticleViews.value = articleViewsSnapshot.size;

    // For story views by category
    final storyViewsSnapshot = await _firestore
        .collection('story_views')
        .get();

    Map<String, int> storyCategoryViews = {};
    for (var doc in storyViewsSnapshot.docs) {
      final data = doc.data();
      final category = data['category'] as String? ?? 'unknown';
      storyCategoryViews[category] = (storyCategoryViews[category] ?? 0) + 1;
    }

    storyViewsByCategory.value = storyCategoryViews;
    totalStoryViews.value = storyViewsSnapshot.size;
  }

  // Face analysis statistics
  Future<void> _fetchFaceAnalysisStatistics() async {
    final analysesSnapshot = await _firestore
        .collection('user_analysis')
        .get();

    Map<String, int> faceShapes = {};
    Map<String, int> colorTypes = {};

    for (var doc in analysesSnapshot.docs) {
      final data = doc.data();

      // Face shapes
      if (data.containsKey('faceShape')) {
        final faceShape = data['faceShape'] as String;
        faceShapes[faceShape] = (faceShapes[faceShape] ?? 0) + 1;
      }

      // Color types
      if (data.containsKey('colorType')) {
        final colorType = data['colorType'] as String;
        colorTypes[colorType] = (colorTypes[colorType] ?? 0) + 1;
      }
    }

    faceShapeDistribution.value = faceShapes;
    colorTypeDistribution.value = colorTypes;
  }

  // Change time filter
  void setTimeFilter(TimeFilter filter) {
    selectedTimeFilter.value = filter;
    fetchAnalyticsData();
  }

  String formatStatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  Map<String, double> calculatePercentages(Map<String, int> data) {
    if (data.isEmpty) return {};

    final total = data.values.fold<int>(0, (sum, count) => sum + count);

    Map<String, double> percentages = {};
    data.forEach((key, value) {
      percentages[key] = (value / total) * 100;
    });

    return percentages;
  }
}

enum TimeFilter {
  last7Days,
  last30Days,
  last90Days,
  lastYear,
}

class AnalyticsDashboard extends StatelessWidget {
  final controller = Get.put(AnalyticsDashboardController());

  AnalyticsDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('analytics_dashboard'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.fetchAnalyticsData,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time filter selection
              _buildTimeFilterSection(context),
              const SizedBox(height: 24),

              // Users statistics
              Text(
                'user_statistics'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Total users card stretched across screen
              _buildStatCard(
                title: 'total_users'.tr,
                value: controller.formatStatCount(controller.totalUsers.value),
                icon: Icons.people,
                color: Colors.blue,
              ),

              const SizedBox(height: 24),

              // User preferences statistics
              Text(
                'user_preferences'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Age distribution
              _buildHistogramCard(
                title: 'age_distribution'.tr,
                data: controller.ageDistribution,
                colors: const [Colors.blue, Colors.lightBlue, Colors.blueAccent],
              ),
              const SizedBox(height: 16),

              // Skin type distribution
              _buildHistogramCard(
                title: 'skin_type_distribution'.tr,
                data: controller.skinTypeDistribution,
                colors: const [Colors.purple, Colors.purpleAccent, Colors.deepPurple],
              ),
              const SizedBox(height: 24),

              // Content statistics
              Text(
                'content_statistics'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Content stats - each card stretched full width
              _buildStatCard(
                title: 'total_articles'.tr,
                value: controller.formatStatCount(controller.totalArticles.value),
                icon: Icons.article,
                color: Colors.purple,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: 'total_stories'.tr,
                value: controller.formatStatCount(controller.totalStories.value),
                icon: Icons.auto_stories,
                color: Colors.amber,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: 'total_analyses'.tr,
                value: controller.formatStatCount(controller.totalAnalyses.value),
                icon: Icons.face,
                color: Colors.pink,
              ),
              const SizedBox(height: 24),

              // Face analysis statistics
              Text(
                'face_analysis_statistics'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Face shape distribution
              _buildDistributionCard(
                title: 'face_shape_distribution'.tr,
                data: controller.faceShapeDistribution,
                percentages: controller.calculatePercentages(controller.faceShapeDistribution),
                colors: const [
                  Colors.blue,
                  Colors.red,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.teal,
                ],
              ),
              const SizedBox(height: 16),

              // Color type distribution
              _buildDistributionCard(
                title: 'color_type_distribution'.tr,
                data: controller.colorTypeDistribution,
                percentages: controller.calculatePercentages(controller.colorTypeDistribution),
                colors: const [
                  Colors.pink,
                  Colors.lightBlue,
                  Colors.amber,
                  Colors.blueGrey,
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTimeFilterSection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'time_period'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              // Responsive time filter selector
              if (MediaQuery.of(context).size.width < 600) {
                // Use a dropdown for narrow screens
                return DropdownButtonFormField<TimeFilter>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  value: controller.selectedTimeFilter.value,
                  items: [
                    DropdownMenuItem(
                      value: TimeFilter.last7Days,
                      child: Text('last_7_days'.tr),
                    ),
                    DropdownMenuItem(
                      value: TimeFilter.last30Days,
                      child: Text('last_30_days'.tr),
                    ),
                    DropdownMenuItem(
                      value: TimeFilter.last90Days,
                      child: Text('last_90_days'.tr),
                    ),
                    DropdownMenuItem(
                      value: TimeFilter.lastYear,
                      child: Text('last_year'.tr),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.setTimeFilter(value);
                    }
                  },
                );
              } else {
                // Use segmented buttons for wider screens
                return SegmentedButton<TimeFilter>(
                  segments: [
                    ButtonSegment(
                      value: TimeFilter.last7Days,
                      label: Text('last_7_days'.tr),
                    ),
                    ButtonSegment(
                      value: TimeFilter.last30Days,
                      label: Text('last_30_days'.tr),
                    ),
                    ButtonSegment(
                      value: TimeFilter.last90Days,
                      label: Text('last_90_days'.tr),
                    ),
                    ButtonSegment(
                      value: TimeFilter.lastYear,
                      label: Text('last_year'.tr),
                    ),
                  ],
                  selected: {controller.selectedTimeFilter.value},
                  onSelectionChanged: (Set<TimeFilter> selection) {
                    controller.setTimeFilter(selection.first);
                  },
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
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
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistogramCard({
    required String title,
    required RxMap<String, int> data,
    required List<Color> colors,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),

            data.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('no_data_available'.tr, style: TextStyle(color: Colors.grey[600])),
              ),
            )
                : _buildHistogram(data, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHistogram(RxMap<String, int> data, List<Color> colors) {
    // Sort data by value in descending order
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Find the maximum value for scaling
    final maxValue = sortedEntries.isEmpty ? 1 : sortedEntries.first.value;

    return Column(
      children: List.generate(
        sortedEntries.length,
            (index) {
          final entry = sortedEntries[index];
          final color = colors[index % colors.length];
          final percentage = (entry.value / maxValue) * 100;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 60,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${entry.value}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDistributionCard({
    required String title,
    required RxMap<String, int> data,
    required Map<String, double> percentages,
    required List<Color> colors,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),

            data.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('no_data_available'.tr, style: TextStyle(color: Colors.grey[600])),
              ),
            )
                : Column(
              children: [
                // Stacked progress indicator
                _buildStackedProgressIndicator(data, percentages, colors),
                const SizedBox(height: 16),

                // Legend
                Column(
                  children: _buildDistributionItems(data, percentages, colors),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStackedProgressIndicator(Map<String, int> data, Map<String, double> percentages, List<Color> colors) {
    // Sort items by percentage in descending order
    List<MapEntry<String, double>> sortedEntries = percentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SizedBox(
      height: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: List.generate(
            sortedEntries.length,
                (index) {
              final entry = sortedEntries[index];
              final color = colors[index % colors.length];
              return Expanded(
                flex: entry.value.toInt(),
                child: Container(
                  color: color,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDistributionItems(
      Map<String, int> data,
      Map<String, double> percentages,
      List<Color> colors,
      ) {
    // Sort items by count in descending order
    List<MapEntry<String, int>> sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Widget> items = [];

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final color = i < colors.length ? colors[i] : colors[i % colors.length];
      final percentage = percentages[entry.key] ?? 0;

      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(
                  '${entry.key}',
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 60,
                alignment: Alignment.centerRight,
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                width: 50,
                alignment: Alignment.centerRight,
                child: Text(
                  '(${entry.value})',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return items;
  }
}