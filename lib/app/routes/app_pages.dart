import 'package:get/get.dart';
import 'package:jg_business/app/routes/app_routes.dart';
import 'package:jg_business/features/auth/data/datasources/google_auth_remote_data_source.dart';
import 'package:jg_business/features/calendar/data/datasources/google_calendar_remote_data_source.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_event_controler.dart';
import 'package:jg_business/features/calendar/presentation/screens/calendar_event_detail_screen.dart';
import 'package:jg_business/features/calendar/presentation/screens/calendar_event_screen.dart';
import 'package:jg_business/features/main/presentation/bindings/main_binding.dart';
import 'package:jg_business/features/main/presentation/screens/main_screen.dart';
import 'package:jg_business/features/meeting/data/repositories/meeting_record_repository.dart';
import 'package:jg_business/features/meeting/presentation/controllers/meeting_record_controller.dart';
import 'package:jg_business/features/meeting/presentation/screens/meeting_record_screen.dart';
import 'package:jg_business/features/onboarding/presentation/screens/calendar_connect_intro_screen.dart';
import 'package:jg_business/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:jg_business/features/splash/presentation/bindings/splash_binding.dart';
import 'package:jg_business/features/splash/presentation/screens/splash_screen.dart';

abstract final class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.main,
      page: () => const MainScreen(),
      binding: MainBinding(),
    ),
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingScreen()),
    GetPage(
      name: AppRoutes.calendarConnectIntro,
      page: () => const CalendarConnectIntroScreen(),
    ),
    GetPage(
      name: AppRoutes.calendarEventDetail,
      page: () {
        final map = Get.arguments as Map<String, dynamic>;
        final event = map['event'] as CalendarEvent;
        return CalendarEventDetailScreen(event: event);
      },
    ),
    GetPage(
      name: AppRoutes.meetingRecord,
      page: () => const MeetingRecordScreen(),
      binding: BindingsBuilder.put(() {
        final event = Get.arguments as CalendarEvent;
        return MeetingRecordController(
          repository: Get.find<MeetingRecordRepository>(),
          authRemoteDataSource: Get.find<GoogleAuthRemoteDataSource>(),
          event: event,
        );
      }),
    ),
    GetPage(
      name: CalendarEventScreen.name,
      page: () {
        return CalendarEventScreen();
      },
      binding: BindingsBuilder.put(() {
        final map = Get.arguments as Map<String, dynamic>;

        final event = map['event'] as CalendarEvent?;
        final date = map['date'] as DateTime;
        return CalendarEventControler(
          remoteDataSource: Get.find<GoogleCalendarRemoteDataSource>(),
          dateTime: date,
          event: event,
        );
      }),
    ),
  ];
}
