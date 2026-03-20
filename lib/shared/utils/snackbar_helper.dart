/// GetX snackbar 호출을 한 곳에서 관리한다.
import 'package:get/get.dart';

abstract final class SnackbarHelper {
  static void success(String title, String message) {
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
  }

  static void error(String title, String message) {
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
  }

  static void info(String title, String message) {
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
  }
}
