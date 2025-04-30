// lib/app/core/utils/app_bindings.dart

import 'package:get/get.dart';
import 'package:marinette/app/data/services/storage_service.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Реєстрація Firebase Storage сервісів
    Get.putAsync(() => StorageService().init(), permanent: true);
  }
}