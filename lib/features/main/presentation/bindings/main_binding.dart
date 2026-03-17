import 'package:get/get.dart';
import 'package:jg_business/features/calendar/presentation/bindings/calendar_binding.dart';
import 'package:jg_business/features/main/presentation/controllers/main_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    CalendarBinding().dependencies();
    Get.put(MainController(), permanent: true);
  }
}
