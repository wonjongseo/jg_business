import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/shared/log/log_manager.dart';

class SnackBarHelper {
  static void showErrorSnackBar(String message) {
    LogManager.error(message);
    Get.rawSnackbar(
      message: message,
      backgroundColor: Colors.red,
      borderRadius: 20,
      margin: EdgeInsets.symmetric(horizontal: 20),
      duration: Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      icon: Icon(Icons.error, color: Colors.white),
    );
  }

  static void showSuccessSnackBar(String message) {
    Get.rawSnackbar(
      message: message,
      backgroundColor: Colors.green,
      borderRadius: 20,
      margin: EdgeInsets.symmetric(horizontal: 20),
      duration: Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      icon: Icon(Icons.check_circle, color: Colors.white),
    );
  }
}
