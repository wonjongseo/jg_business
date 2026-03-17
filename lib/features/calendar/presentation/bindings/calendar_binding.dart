import 'package:get/get.dart';
import 'package:jg_business/features/auth/data/datasources/google_auth_remote_data_source.dart';
import 'package:jg_business/features/calendar/data/datasources/google_calendar_remote_data_source.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:jg_business/shared/services/notification_service.dart';

class CalendarBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GoogleAuthRemoteDataSource>(
      () => GoogleAuthRemoteDataSource(),
      fenix: true,
    );
    Get.lazyPut<GoogleCalendarRemoteDataSource>(
      () => GoogleCalendarRemoteDataSource(
        authRemoteDataSource: Get.find<GoogleAuthRemoteDataSource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<NotificationService>(() => NotificationService(), fenix: true);
    Get.lazyPut<CalendarController>(
      () => CalendarController(
        remoteDataSource: Get.find<GoogleCalendarRemoteDataSource>(),
        notificationService: Get.find<NotificationService>(),
      ),
      fenix: true,
    );
  }
}
