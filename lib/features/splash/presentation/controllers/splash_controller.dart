import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:jg_business/app/routes/app_routes.dart';
import 'package:jg_business/shared/services/notification_service.dart';

class SplashController extends GetxController {
  SplashController({required NotificationService notificationService})
    : _notificationService = notificationService;

  final NotificationService _notificationService;

  @override
  void onInit() {
    super.onInit();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _notificationService.initialize();
      await _notificationService.requestPermissions();
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed(AppRoutes.main);
    });
  }
}
