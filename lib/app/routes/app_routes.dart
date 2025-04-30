// lib/app/routes/app_routes.dart

import 'package:get/get.dart';
import 'package:marinette/app/modules/home/home_screen.dart';
import 'package:marinette/app/modules/profile/profile_screen.dart';
import 'package:marinette/app/modules/beauty_hub/beauty_hub_screen.dart';
import 'package:marinette/app/modules/auth/auth_screen.dart';
import 'package:marinette/app/modules/admin/admin_panel_screen.dart';
import 'package:marinette/app/modules/admin/articles/articles_management_screen.dart';
import 'package:marinette/app/modules/admin/stories/stories_management_screen.dart';
import 'package:marinette/app/modules/admin/daily_tips/daily_tips_management_screen.dart';
import 'package:marinette/app/modules/admin/beauty_trends/beauty_trends_management_screen.dart';
import 'package:marinette/app/core/middlewares/auth_middleware.dart';

class AppRoutes {
  static const String HOME = '/';
  static const String PROFILE = '/profile';
  static const String BEAUTY_HUB = '/beauty-hub';
  static const String AUTH = '/auth';
  static const String ADMIN = '/admin';
  static const String ARTICLES_MANAGEMENT = '/admin/articles';
  static const String STORIES_MANAGEMENT = '/admin/stories';
  static const String DAILY_TIPS_MANAGEMENT = '/admin/daily-tips';
  static const String BEAUTY_TRENDS_MANAGEMENT = '/admin/beauty-trends';

  static final routes = [
    GetPage(
      name: HOME,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: PROFILE,
      page: () => ProfileScreen(),
    ),
    GetPage(
      name: BEAUTY_HUB,
      page: () => const BeautyHubScreen(),
    ),
    GetPage(
      name: AUTH,
      page: () => AuthScreen(),
    ),
    GetPage(
      name: ADMIN,
      page: () => AdminPanelScreen(),
      middlewares: [
        AdminMiddleware(),
      ],
    ),
    GetPage(
      name: ARTICLES_MANAGEMENT,
      page: () => ArticlesManagementScreen(),
      middlewares: [
        AdminMiddleware(),
      ],
    ),
    GetPage(
      name: STORIES_MANAGEMENT,
      page: () => StoriesManagementScreen(),
      middlewares: [
        AdminMiddleware(),
      ],
    ),
    GetPage(
      name: DAILY_TIPS_MANAGEMENT,
      page: () => DailyTipsManagementScreen(),
      middlewares: [
        AdminMiddleware(),
      ],
    ),
    GetPage(
      name: BEAUTY_TRENDS_MANAGEMENT,
      page: () => BeautyTrendsManagementScreen(),
      middlewares: [
        AdminMiddleware(),
      ],
    ),
  ];
}