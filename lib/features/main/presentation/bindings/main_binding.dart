/// 메인 탭 진입 시 필요한 의존성을 묶어 등록한다.
import 'package:get/get.dart';
import 'package:jg_business/features/auth/presentation/controllers/auth_controller.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:jg_business/features/calendar/presentation/bindings/calendar_binding.dart';
import 'package:jg_business/features/client/presentation/controllers/client_controller.dart';
import 'package:jg_business/features/client/data/repositories/client_repository.dart';
import 'package:jg_business/features/meeting/data/repositories/meeting_record_repository.dart';
import 'package:jg_business/features/main/presentation/controllers/main_controller.dart';
import 'package:jg_business/shared/services/notification_service.dart';
import 'package:jg_business/shared/services/theme_service.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    CalendarBinding().dependencies();
    Get.put(
      ClientController(
        repository: Get.find<ClientRepository>(),
        authController: Get.find<AuthController>(),
        meetingRecordRepository: Get.find<MeetingRecordRepository>(),
      ),
      permanent: true,
    );
    Get.put(
      MainController(
        authController: Get.find<AuthController>(),
        calendarController: Get.find<CalendarController>(),
        notificationService: Get.find<NotificationService>(),
        themeService: Get.find<ThemeService>(),
      ),
      permanent: true,
    );
  }
}
