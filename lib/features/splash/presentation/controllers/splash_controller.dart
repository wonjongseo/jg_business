import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:jg_business/app/routes/app_routes.dart';
import 'package:jg_business/shared/services/app_launch_service.dart';
import 'package:jg_business/shared/services/notification_service.dart';

class SplashController extends GetxController {
  SplashController({
    required NotificationService notificationService,
    required AppLaunchService appLaunchService,
  }) : _notificationService = notificationService,
       _appLaunchService = appLaunchService;

  final NotificationService _notificationService;
  final AppLaunchService _appLaunchService;

  @override
  void onInit() {
    super.onInit();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _notificationService.initialize();
      await _notificationService.requestPermissions();
      await Future.delayed(const Duration(milliseconds: 500));
      final onboardingCompleted =
          await _appLaunchService.isOnboardingCompleted();
      Get.offAllNamed(
        onboardingCompleted ? AppRoutes.main : AppRoutes.onboarding,
      );
    });
  }
}
