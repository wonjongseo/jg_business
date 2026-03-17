/// 화면 하단 피드백 메시지 스타일을 공용화한다.
import 'package:get/get.dart';

abstract final class AppFeedback {
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
