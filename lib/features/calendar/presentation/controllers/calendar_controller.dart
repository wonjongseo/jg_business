import 'package:calendar_view/calendar_view.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/calendar/data/datasources/google_calendar_remote_data_source.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/features/calendar/presentation/mappers/calendar_event_mapper.dart';
import 'package:jg_business/features/calendar/presentation/screens/calendar_day_screen.dart';
import 'package:jg_business/features/calendar/presentation/screens/calendar_event_screen.dart';

enum CalendarDisplayMode { month, week }

class CalendarController extends GetxController {
  CalendarController({required GoogleCalendarRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final GoogleCalendarRemoteDataSource _remoteDataSource;

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final _events = <CalendarEvent>[].obs;

  final calendarEventController = EventController<CalendarEvent>();

  final _displayMode = CalendarDisplayMode.month.obs;
  CalendarDisplayMode get displayMode => _displayMode.value;

  final focusedDay = DateTime.now().obs;

  void changeDisplayMode(CalendarDisplayMode mode) {
    _displayMode.value = mode;
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
    fetchCalendar();
  }

  Future<void> fetchCalendar() async {
    try {
      _isLoading.value = true;
      final result = await _remoteDataSource.fetchEvents();

      _events.assignAll(result);

      calendarEventController.removeWhere((event) => true);
      calendarEventController.addAll(
        CalendarEventMapper.toCalendarViewEvents(result),
      );
    } catch (e) {
      print('e.toString() : ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  void openDayView(DateTime date) {
    focusedDay.value = date;
    Get.toNamed(CalendarDayScreen.name, arguments: date);
  }

  void goToEventScreen({
    List<CalendarEventData<CalendarEvent>>? events,
    required DateTime date,
  }) {
    final selectedEvent = events?.firstOrNull?.event;

    Get.toNamed(
      CalendarEventScreen.name,
      arguments: {'event': selectedEvent, 'date': date},
    );
  }

  @override
  void onClose() {
    calendarEventController.dispose();
    super.onClose();
  }

  Future<void> reauthenticate() async {
    await _remoteDataSource.reauthenticate();
    await fetchCalendar();
  }

  Future<void> addSampleEvent() async {
    final start = DateTime.now().add(const Duration(hours: 1));
    final end = start.add(const Duration(hours: 1));

    await _remoteDataSource.createEvent(
      summary: '새 미팅',
      description: '앱에서 추가한 일정',
      location: '종각',
      start: start,
      end: end,
    );

    await fetchCalendar();
  }

  Future<void> editEvent(CalendarEvent event) async {
    if (event.id == null) return;

    final start = (event.start?.dateTime ?? DateTime.now()).add(
      const Duration(hours: 1),
    );
    final end = (event.end?.dateTime ?? start).add(const Duration(hours: 1));

    await _remoteDataSource.updateEvent(
      eventId: event.id!,
      summary: '${event.summary ?? '일정'} 수정됨',
      start: start,
      end: end,
    );

    await fetchCalendar();
  }
}
