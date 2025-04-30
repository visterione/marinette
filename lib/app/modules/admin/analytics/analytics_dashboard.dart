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
  final RxInt activeUsersLast7Days = 0.obs;
  final RxInt newUsersLast30Days = 0.obs;

  // Content statistics
  final RxInt totalArticles = 0.obs;
  final RxInt totalStories = 0.obs;
  final RxInt totalAnalyses = 0.obs;

  // Engagement statistics
  final RxInt totalArticleViews = 0.obs;
  final RxInt totalStoryViews = 0.obs;
  final RxMap<String, int> articleViewsByCategory = <String, int>{}.obs;
  final RxMap<String, int> storyViewsByCategory = <String, int>{}.obs;

  // Time-based statistics
  final RxList<Map<String, dynamic>> userSignupsByWeek = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> analysesByDay = <Map<String, dynamic>>[].obs;

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
        _fetchTimeBasedStatistics(),
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

    // Get active users in last 7 days
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final activeUsersSnapshot = await _firestore
        .collection('users')
        .where('lastLogin', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
        .get();
    activeUsersLast7Days.value = activeUsersSnapshot.size;

    // Get new users in last 30 days
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final newUsersSnapshot = await _firestore
        .collection('users')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
        .get();
    newUsersLast30Days.value = newUsersSnapshot.size;
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

  // Time-based statistics
  Future<void> _fetchTimeBasedStatistics() async {
    // Get user signups by week
    final DateTime endDate = DateTime.now();
    DateTime startDate;

    switch (selectedTimeFilter.value) {
      case TimeFilter.last7Days:
        startDate = endDate.subtract(const Duration(days: 7));
        break;
      case TimeFilter.last30Days:
        startDate = endDate.subtract(const Duration(days: 30));
        break;
      case TimeFilter.last90Days:
        startDate = endDate.subtract(const Duration(days: 90));
        break;
      case TimeFilter.lastYear:
        startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
        break;
    }

    final usersSnapshot = await _firestore
        .collection('users')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('createdAt')
        .get();

    // Group by week
    Map<String, int> signupsByWeek = {};
    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp).toDate();
      final weekStart = _getStartOfWeek(createdAt);
      final weekKey = DateFormat('yyyy-MM-dd').format(weekStart);

      signupsByWeek[weekKey] = (signupsByWeek[weekKey] ?? 0) + 1;
    }

    // Convert to a list for easy charting
    List<Map<String, dynamic>> signupData = [];
    signupsByWeek.forEach((date, count) {
      signupData.add({
        'date': date,
        'count': count,
      });
    });

    // Sort by date
    signupData.sort((a, b) => a['date'].compareTo(b['date']));
    userSignupsByWeek.value = signupData;

    // Get analyses by day
    final analysesSnapshot = await _firestore
        .collection('user_analysis')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('createdAt')
        .get();

    // Group by day
    Map<String, int> analysesByDayMap = {};
    for (var doc in analysesSnapshot.docs) {
      final data = doc.data();
      if (data.containsKey('createdAt')) {
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final dayKey = DateFormat('yyyy-MM-dd').format(createdAt);

        analysesByDayMap[dayKey] = (analysesByDayMap[dayKey] ?? 0) + 1;
      }
    }

    // Convert to a list for easy charting
    List<Map<String, dynamic>> analysesData = [];
    analysesByDayMap.forEach((date, count) {
      analysesData.add({
        'date': date,
        'count': count,
      });
    });

    // Sort by date
    analysesData.sort((a, b) => a['date'].compareTo(b['date']));
    analysesByDay.value = analysesData;
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

  // Helper to get the start of a week for a given date
  DateTime _getStartOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day - date.weekday + 1);
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
              _buildTimeFilterSection(),
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
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'total_users'.tr,
                      value: controller.formatStatCount(controller.totalUsers.value),
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'active_users_7days'.tr,
                      value: controller.formatStatCount(controller.activeUsersLast7Days.value),
                      icon: Icons.person_outline,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'new_users_30days'.tr,
                      value: controller.formatStatCount(controller.newUsersLast30Days.value),
                      icon: Icons.person_add,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // User signups over time
              _buildUserSignupsChart(),
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
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'total_articles'.tr,
                      value: controller.formatStatCount(controller.totalArticles.value),
                      icon: Icons.article,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'total_stories'.tr,
                      value: controller.formatStatCount(controller.totalStories.value),
                      icon: Icons.auto_stories,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'total_analyses'.tr,
                      value: controller.formatStatCount(controller.totalAnalyses.value),
                      icon: Icons.face,
                      color: Colors.pink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Analyses over time
              _buildAnalysesChart(),
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

  Widget _buildTimeFilterSection() {
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
            Obx(() => SegmentedButton<TimeFilter>(
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
            )),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
    );
  }

  Widget _buildUserSignupsChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'user_signups_over_time'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: controller.userSignupsByWeek.isEmpty
                  ? Center(
                child: Text('no_data_available'.tr, style: TextStyle(color: Colors.grey[600])),
              )
                  : _buildBarChart(
                data: controller.userSignupsByWeek,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysesChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analyses_over_time'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: controller.analysesByDay.isEmpty
                  ? Center(
                child: Text('no_data_available'.tr, style: TextStyle(color: Colors.grey[600])),
              )
                  : _buildBarChart(
                data: controller.analysesByDay,
                color: Colors.pink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart({
    required List<Map<String, dynamic>> data,
    required Color color,
  }) {
    // Find the maximum value for scaling
    final maxValue = data.isEmpty
        ? 1
        : data.map((item) => item['count'] as int).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((item) {
              final value = item['count'] as int;
              final date = item['date'] as String;
              final height = (value / maxValue) * 150; // Scale height

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    value.toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: constraints.maxWidth / (data.length * 2),
                    height: height,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 40,
                    child: Text(
                      _formatDateLabel(date),
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  String _formatDateLabel(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('MM/dd').format(date);
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
                // Stacked progress bars
                LinearProgressIndicator(
                  value: 1,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent),
                  minHeight: 20,
                ),
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
          padding: const EdgeInsets.only(bottom: 8),
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
                child: Text(
                  '${entry.key.tr}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${entry.value})',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
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