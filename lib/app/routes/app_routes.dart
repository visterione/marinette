// lib/app/routes/app_routes.dart

import 'package:get/get.dart';
import 'package:marinette/app/modules/home/home_screen.dart';
import 'package:marinette/app/modules/profile/profile_screen.dart';
import 'package:marinette/app/modules/beauty_hub/beauty_hub_screen.dart';
import 'package:marinette/app/modules/auth/auth_screen.dart';
import 'package:marinette/app/modules/admin/admin_panel_screen.dart';
import 'package:marinette/app/modules/admin/migration_screen.dart';
import 'package:marinette/app/data/services/auth_service.dart';
import 'package:marinette/app/core/middlewares/auth_middleware.dart';

class AppRoutes {
  static const String HOME = '/';
  static const String PROFILE = '/profile';
  static const String BEAUTY_HUB = '/beauty-hub';
  static const String AUTH = '/auth';
  static const String ADMIN = '/admin';
  static const String MIGRATION = '/admin/migration';

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
      name: MIGRATION,
      page: () => const MigrationScreen(),
      middlewares: [
        AdminMiddleware(),
      ],
    ),
  ];
}