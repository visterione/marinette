import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/services/auth_service.dart';
import 'package:marinette/app/data/services/result_saver_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final ResultSaverService _resultSaverService = Get.find<ResultSaverService>();

  RxBool get isLoading => _authService.isLoading;

  // Авторизація через Google
  Future<void> signInWithGoogle() async {
    final success = await _authService.signInWithGoogle();

    if (success) {
      // Получаем userId текущего пользователя
      final userId = _authService.currentUser!.uid;

      // Проверяем наличие локальных результатов, принадлежащих текущему пользователю
      final results = await _resultSaverService.getAllResults();
      final unsyncedResults = results.where((result) =>
      // Проверяем, что результаты принадлежат текущему пользователю или не имеют владельца
      (result['userId'] == userId || result['userId'] == null) &&
          // Проверяем, что результаты не синхронизированы
          (result['synced'] != true || !result.containsKey('firestoreId'))
      ).toList();

      if (unsyncedResults.isNotEmpty) {
        Get.dialog(
          AlertDialog(
            title: Text('sync_results'.tr),
            content: Text(
              'sync_results_message'.trParams(
                  {'count': unsyncedResults.length.toString()}
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('later'.tr),
              ),
              TextButton(
                onPressed: () async {
                  Get.back();
                  await _resultSaverService.syncResultsToFirestore();
                  Get.snackbar(
                    'success'.tr,
                    'results_synced_successfully'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                child: Text('sync_now'.tr),
              ),
            ],
          ),
        );
      }
    } else {
      Get.snackbar(
        'error'.tr,
        'google_sign_in_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}