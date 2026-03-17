import 'package:get/get.dart';
import 'package:jg_business/features/splash/presentation/controllers/splash_controller.dart';
import 'package:jg_business/shared/services/app_launch_service.dart';
import 'package:jg_business/shared/services/notification_service.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppLaunchService>(() => AppLaunchService(), fenix: true);
    Get.lazyPut<NotificationService>(() => NotificationService(), fenix: true);
    Get.put(
      SplashController(
        notificationService: Get.find<NotificationService>(),
        appLaunchService: Get.find<AppLaunchService>(),
      ),
    );
  }
}
