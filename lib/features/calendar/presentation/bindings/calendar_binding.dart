/// 캘린더 기능에서 필요한 의존성을 GetX에 등록한다.
import 'package:get/get.dart';
import 'package:jg_business/features/auth/data/datasources/google_auth_remote_data_source.dart';
import 'package:jg_business/features/auth/presentation/controllers/auth_controller.dart';
import 'package:jg_business/features/business_card/data/datasources/business_card_firestore_data_source.dart';
import 'package:jg_business/features/business_card/data/repositories/business_card_repository.dart';
import 'package:jg_business/features/calendar/data/datasources/google_calendar_remote_data_source.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:jg_business/features/client/data/datasources/client_firestore_data_source.dart';
import 'package:jg_business/features/client/data/repositories/client_repository.dart';
import 'package:jg_business/features/meeting/data/datasources/meeting_record_firestore_data_source.dart';
import 'package:jg_business/features/meeting/data/datasources/meeting_status_firestore_data_source.dart';
import 'package:jg_business/features/meeting/data/repositories/meeting_record_repository.dart';
import 'package:jg_business/features/meeting/data/repositories/meeting_status_repository.dart';
import 'package:jg_business/features/spreadsheet_sync/data/datasources/google_sheets_remote_data_source.dart';
import 'package:jg_business/features/spreadsheet_sync/data/repositories/spreadsheet_sync_repository.dart';
import 'package:jg_business/shared/services/notification_service.dart';

class CalendarBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GoogleAuthRemoteDataSource>(
      () => GoogleAuthRemoteDataSource(),
      fenix: true,
    );
    Get.lazyPut<AuthController>(
      () => AuthController(
        authRemoteDataSource: Get.find<GoogleAuthRemoteDataSource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<GoogleCalendarRemoteDataSource>(
      () => GoogleCalendarRemoteDataSource(
        authRemoteDataSource: Get.find<GoogleAuthRemoteDataSource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<NotificationService>(() => NotificationService(), fenix: true);
    Get.lazyPut<ClientFirestoreDataSource>(
      () => ClientFirestoreDataSource(),
      fenix: true,
    );
    Get.lazyPut<ClientRepository>(
      () => ClientRepository(
        firestoreDataSource: Get.find<ClientFirestoreDataSource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<BusinessCardFirestoreDataSource>(
      () => BusinessCardFirestoreDataSource(),
      fenix: true,
    );
    Get.lazyPut<BusinessCardRepository>(
      () => BusinessCardRepository(
        firestoreDataSource: Get.find<BusinessCardFirestoreDataSource>(),
      ),
      fenix: true,
    );
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
    Get.lazyPut<MeetingStatusFirestoreDataSource>(
      () => MeetingStatusFirestoreDataSource(),
      fenix: true,
    );
    Get.lazyPut<MeetingStatusRepository>(
      () => MeetingStatusRepository(
        firestoreDataSource: Get.find<MeetingStatusFirestoreDataSource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<GoogleSheetsRemoteDataSource>(
      () => GoogleSheetsRemoteDataSource(
        authRemoteDataSource: Get.find<GoogleAuthRemoteDataSource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<SpreadsheetSyncRepository>(
      () => SpreadsheetSyncRepository(
        remoteDataSource: Get.find<GoogleSheetsRemoteDataSource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<CalendarController>(
      () => CalendarController(
        remoteDataSource: Get.find<GoogleCalendarRemoteDataSource>(),
        notificationService: Get.find<NotificationService>(),
        authController: Get.find<AuthController>(),
        meetingRecordRepository: Get.find<MeetingRecordRepository>(),
        meetingStatusRepository: Get.find<MeetingStatusRepository>(),
      ),
      fenix: true,
    );
  }
}
