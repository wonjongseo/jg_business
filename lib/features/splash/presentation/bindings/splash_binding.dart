import 'package:get/get.dart';
import 'package:jg_business/features/splash/presentation/controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SplashController());
  }
}
