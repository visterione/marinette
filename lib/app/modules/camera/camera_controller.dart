import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomCameraController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  Rx<CameraController?> cameraController = Rx<CameraController?>(null);
  RxBool isCameraInitialized = false.obs;
  RxBool hasPermission = false.obs;

  @override
  void onInit() async {
    super.onInit();
    await _checkPermissions();
  }

  @override
  void onClose() {
    cameraController.value?.dispose();
    super.onClose();
  }

  Future<void> _checkPermissions() async {
    try {
      final camera = await Permission.camera.status;
      if (camera.isGranted) {
        hasPermission.value = true;
        await _initializeCamera();
      } else {
        final result = await Permission.camera.request();
        hasPermission.value = result.isGranted;
        if (result.isGranted) {
          await _initializeCamera();
        }
      }
    } catch (e) {
      print('Error checking permissions: $e');
      Get.snackbar('error'.tr, 'error_camera'.tr);
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('No cameras available');
        return;
      }

      final controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      cameraController.value = controller;
      isCameraInitialized.value = true;
    } catch (e) {
      print('Error initializing camera: $e');
      Get.snackbar('error'.tr, 'error_camera'.tr);
    }
  }

  Future<String?> takePhoto() async {
    try {
      if (!isCameraInitialized.value || cameraController.value == null) {
        print('Camera not initialized');
        return null;
      }

      final XFile image = await cameraController.value!.takePicture();
      print('Photo taken: ${image?.path}');
      return image?.path;
    } catch (e) {
      print('Error taking photo: $e');
      Get.snackbar('error'.tr, 'error_camera'.tr);
      return null;
    }
  }

  Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      print('Image picked: ${image?.path}');
      return image?.path;
    } catch (e) {
      print('Error picking image: $e');
      Get.snackbar('error'.tr, 'Could not pick image from gallery'.tr);
      return null;
    }
  }
}
