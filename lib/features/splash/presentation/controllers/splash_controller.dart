import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:jg_business/app/routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed(AppRoutes.main);
    });
  }
}
