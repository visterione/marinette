import 'package:get/get.dart';
import 'package:marinette/app/data/services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  RxBool get isLoading => _authService.isLoading;

  // Авторизація через Google
  Future<void> signInWithGoogle() async {
    final success = await _authService.signInWithGoogle();

    if (!success) {
      Get.snackbar(
        'error'.tr,
        'google_sign_in_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}