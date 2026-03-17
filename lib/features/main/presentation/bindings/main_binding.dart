import 'package:get/get.dart';
import 'package:jg_business/features/auth/data/datasources/google_auth_remote_data_source.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:jg_business/features/calendar/presentation/bindings/calendar_binding.dart';
import 'package:jg_business/features/meeting/data/datasources/meeting_record_firestore_data_source.dart';
import 'package:jg_business/features/meeting/data/repositories/meeting_record_repository.dart';
import 'package:jg_business/features/main/presentation/controllers/main_controller.dart';
import 'package:jg_business/shared/services/notification_service.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    CalendarBinding().dependencies();
    Get.lazyPut<MeetingRecordFirestoreDataSource>(
      () => MeetingRecordFirestoreDataSource(),
      fenix: true,
    );
    Get.lazyPut<MeetingRecordRepository>(
      () => MeetingRecordRepository(
        firestoreDataSource: Get.find<MeetingRecordFirestoreDataSource>(),
      ),
      fenix: true,
    );
    Get.put(
      MainController(
        googleAuthRemoteDataSource: Get.find<GoogleAuthRemoteDataSource>(),
        calendarController: Get.find<CalendarController>(),
        notificationService: Get.find<NotificationService>(),
      ),
      permanent: true,
    );
  }
}
