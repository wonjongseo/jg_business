import 'package:calendar_view/calendar_view.dart';
import 'package:get/get.dart';
import 'package:jg_business/app/routes/app_routes.dart';
import 'package:jg_business/features/calendar/data/datasources/google_calendar_remote_data_source.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/features/calendar/presentation/mappers/calendar_event_mapper.dart';
import 'package:jg_business/features/calendar/presentation/screens/calendar_event_screen.dart';
import 'package:jg_business/shared/services/notification_service.dart';

class CalendarController extends GetxController {
  CalendarController({
    required GoogleCalendarRemoteDataSource remoteDataSource,
    required NotificationService notificationService,
  }) : _remoteDataSource = remoteDataSource,
       _notificationService = notificationService;

  final GoogleCalendarRemoteDataSource _remoteDataSource;
  final NotificationService _notificationService;

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final _isConnected = false.obs;
  bool get isConnected => _isConnected.value;

  final _events = <CalendarEvent>[].obs;
  List<CalendarEvent> get events => _events;

  // Home and calendar summary panels both depend on the same "what matters now"
  // interpretation: ongoing meeting first, otherwise the next upcoming one.
  CalendarEvent? get currentOrNextEvent {
    final now = DateTime.now();

    for (final event in _events) {
      final end = event.end?.dateTime ?? event.end?.date;
      if (end == null || !end.isBefore(now)) {
        return event;
      }
    }

    return null;
  }

  final calendarEventController = EventController<CalendarEvent>();

  final focusedDay = DateTime.now().obs;

  List<CalendarEvent> get todayEvents {
    final today = DateTime.now();
    return _events.where((event) => occursOnDate(event, today)).toList();
  }

  List<CalendarEvent> get upcomingEvents {
    final now = DateTime.now();
    return _events.where((event) {
      final start = event.start?.dateTime ?? event.start?.date;
      final end = event.end?.dateTime ?? event.end?.date;
      if (start == null && end == null) return false;
      return (end ?? start) != null && !(end ?? start)!.isBefore(now);
    }).take(6).toList();
  }

  List<CalendarEvent> get focusedDayEvents {
    return _events.where((event) => occursOnDate(event, focusedDay.value)).toList();
  }

  bool isOngoing(CalendarEvent event) {
    final now = DateTime.now();
    final start = event.start?.dateTime ?? event.start?.date;
    final end = event.end?.dateTime ?? event.end?.date;

    if (start == null || end == null) return false;
    return !start.isAfter(now) && end.isAfter(now);
  }

  bool occursOnDate(CalendarEvent event, DateTime date) {
    final start = event.start?.dateTime ?? event.start?.date;
    final end = event.end?.dateTime ?? event.end?.date ?? start;
    if (start == null || end == null) return false;

    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    return !targetDate.isBefore(startDate) && !targetDate.isAfter(endDate);
  }

  void changeFocusedDay(DateTime date) {
    focusedDay.value = date;
  }

  void syncFocusedDay(DateTime date) {
    final current = focusedDay.value;
    if (current.year == date.year &&
        current.month == date.month &&
        current.day == date.day) {
      return;
    }
    focusedDay.value = date;
  }

  @override
  void onInit() async {
    super.onInit();
    await _remoteDataSource.initialize();
    _isConnected.value = _remoteDataSource.isConnected;
    await fetchCalendar(interactive: false);
  }

  Future<void> fetchCalendar({bool interactive = true}) async {
    try {
      _isLoading.value = true;
      final result = await _remoteDataSource.fetchEvents(
        interactive: interactive,
      );
      _isConnected.value = _remoteDataSource.isConnected;

      _events.assignAll(result);

      calendarEventController.removeWhere((event) => true);
      calendarEventController.addAll(
        CalendarEventMapper.toCalendarViewEvents(result),
      );
      await _notificationService.resyncCalendarNotifications(result);
    } catch (e) {
      print('e.toString() : ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  void openEventDetail(CalendarEvent event) {
    Get.toNamed(
      AppRoutes.calendarEventDetail,
      arguments: {'event': event},
    );
  }

  void goToEventScreen({
    List<CalendarEventData<CalendarEvent>>? events,
    required DateTime date,
  }) {
    final selectedEvent = events != null && events.isNotEmpty
        ? events.first.event
        : null;

    Get.toNamed(
      CalendarEventScreen.name,
      arguments: {'event': selectedEvent, 'date': date},
    );
  }

  void openEventEditor(CalendarEvent event) {
    final date =
        event.start?.dateTime ?? event.start?.date ?? focusedDay.value;
    Get.toNamed(
      CalendarEventScreen.name,
      arguments: {'event': event, 'date': date},
    );
  }

  @override
  void onClose() {
    calendarEventController.dispose();
    super.onClose();
  }

  Future<void> connectCalendar() async {
    try {
      // Connection CTA should switch the UI into a loading state immediately.
      _isLoading.value = true;
      await _remoteDataSource.reauthenticate();
      _isConnected.value = _remoteDataSource.isConnected;

      if (_isConnected.value) {
        final result = await _remoteDataSource.fetchEvents(interactive: false);
        _events.assignAll(result);

        calendarEventController.removeWhere((event) => true);
        calendarEventController.addAll(
          CalendarEventMapper.toCalendarViewEvents(result),
        );
        await _notificationService.resyncCalendarNotifications(result);
      }
    } catch (e) {
      print('connectCalendar error: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

}
