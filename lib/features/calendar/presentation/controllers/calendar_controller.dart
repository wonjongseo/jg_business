/// 캘린더 탭과 홈 대시보드에서 공용으로 쓰는 일정 상태 컨트롤러다.
import 'package:calendar_view/calendar_view.dart';
import 'package:get/get.dart';
import 'package:jg_business/app/routes/app_routes.dart';
import 'package:jg_business/features/auth/data/datasources/google_auth_remote_data_source.dart';
import 'package:jg_business/features/calendar/data/datasources/google_calendar_remote_data_source.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/features/calendar/presentation/mappers/calendar_event_mapper.dart';
import 'package:jg_business/features/calendar/presentation/screens/calendar_event_screen.dart';
import 'package:jg_business/features/meeting/data/models/meeting_record_entity.dart';
import 'package:jg_business/features/meeting/data/models/meeting_status_entity.dart';
import 'package:jg_business/features/meeting/data/repositories/meeting_record_repository.dart';
import 'package:jg_business/features/meeting/data/repositories/meeting_status_repository.dart';
import 'package:jg_business/features/spreadsheet_sync/data/repositories/spreadsheet_sync_repository.dart';
import 'package:jg_business/shared/services/notification_service.dart';
import 'package:jg_business/shared/utils/app_feedback.dart';

class CalendarController extends GetxController {
  CalendarController({
    required GoogleCalendarRemoteDataSource remoteDataSource,
    required NotificationService notificationService,
    required GoogleAuthRemoteDataSource authRemoteDataSource,
    required MeetingRecordRepository meetingRecordRepository,
    required MeetingStatusRepository meetingStatusRepository,
    required SpreadsheetSyncRepository spreadsheetSyncRepository,
  }) : _remoteDataSource = remoteDataSource,
       _notificationService = notificationService,
       _authRemoteDataSource = authRemoteDataSource,
       _meetingRecordRepository = meetingRecordRepository,
       _meetingStatusRepository = meetingStatusRepository,
       _spreadsheetSyncRepository = spreadsheetSyncRepository;

  final GoogleCalendarRemoteDataSource _remoteDataSource;
  final NotificationService _notificationService;
  final GoogleAuthRemoteDataSource _authRemoteDataSource;
  final MeetingRecordRepository _meetingRecordRepository;
  final MeetingStatusRepository _meetingStatusRepository;
  final SpreadsheetSyncRepository _spreadsheetSyncRepository;

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final _isConnected = false.obs;
  bool get isConnected => _isConnected.value;

  final _events = <CalendarEvent>[].obs;
  List<CalendarEvent> get events => _events;
  final _meetingStatuses = <String, MeetingStatusEntity>{}.obs;
  final _meetingRecords = <String, MeetingRecordEntity>{}.obs;
  final _syncingRecordIds = <String>{}.obs;

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

  List<MeetingRecordEntity> get recentMeetingRecords {
    final records = _meetingRecords.values.toList();
    records.sort((a, b) {
      final left = a.updatedAt ?? a.scheduledStartAt ?? DateTime(1970);
      final right = b.updatedAt ?? b.scheduledStartAt ?? DateTime(1970);
      return right.compareTo(left);
    });
    return records.take(3).toList();
  }

  List<CalendarEvent> get pendingRecordEvents {
    final pendingEventIds = _meetingStatuses.values
        .where((status) => status.recordStatus == 'pending')
        .map((status) => status.googleEventId)
        .toSet();

    return _events
        .where((event) => event.id != null && pendingEventIds.contains(event.id))
        .take(3)
        .toList();
  }

  int get pendingRecordCount =>
      _meetingStatuses.values.where((status) => status.recordStatus == 'pending').length;

  MeetingStatusEntity? statusForEvent(CalendarEvent event) {
    final eventId = event.id;
    if (eventId == null) return null;
    return _meetingStatuses[eventId];
  }

  MeetingRecordEntity? recordForEvent(CalendarEvent event) {
    final eventId = event.id;
    if (eventId == null) return null;
    return _meetingRecords[eventId];
  }

  bool isSyncingRecord(String recordId) => _syncingRecordIds.contains(recordId);

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
      await _syncMeetingStatuses(result);
      await _syncMeetingRecords(result);

      calendarEventController.removeWhere((event) => true);
      calendarEventController.addAll(
        CalendarEventMapper.toCalendarViewEvents(result),
      );
      await _notificationService.resyncCalendarNotifications(
        result,
        completedRecordEventIds: _completedRecordEventIds,
      );
    } catch (_) {
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
        await _syncMeetingStatuses(result);
        await _syncMeetingRecords(result);

        calendarEventController.removeWhere((event) => true);
        calendarEventController.addAll(
          CalendarEventMapper.toCalendarViewEvents(result),
        );
        await _notificationService.resyncCalendarNotifications(
          result,
          completedRecordEventIds: _completedRecordEventIds,
        );
      }
    } catch (_) {
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> syncRecordToSheets(CalendarEvent event) async {
    final record = recordForEvent(event);
    if (record == null) {
      AppFeedback.info(
        '同期不可',
        '先にミーティング記録を保存してください。',
      );
      return;
    }
    if (_syncingRecordIds.contains(record.id)) return;

    final attemptedAt = DateTime.now();
    _syncingRecordIds.add(record.id);
    _syncingRecordIds.refresh();

    try {
      await _meetingRecordRepository.updateSheetsSyncState(
        recordId: record.id,
        status: 'syncing',
        attemptedAt: attemptedAt,
        errorCode: null,
      );
      await _spreadsheetSyncRepository.syncMeetingRecord(record);
      await _meetingRecordRepository.updateSheetsSyncState(
        recordId: record.id,
        status: 'synced',
        attemptedAt: attemptedAt,
        syncedAt: DateTime.now(),
        errorCode: null,
      );
      await _syncMeetingRecords(_events);
      AppFeedback.success(
        '同期完了',
        'ミーティング記録を Google Sheets に同期しました。',
      );
    } catch (error) {
      await _meetingRecordRepository.updateSheetsSyncState(
        recordId: record.id,
        status: 'failed',
        attemptedAt: attemptedAt,
        errorCode: _mapSyncError(error),
      );
      await _syncMeetingRecords(_events);
      AppFeedback.error(
        '同期失敗',
        _syncErrorMessage(error),
      );
    } finally {
      _syncingRecordIds.remove(record.id);
      _syncingRecordIds.refresh();
    }
  }

  Future<void> _syncMeetingStatuses(List<CalendarEvent> events) async {
    final userId = _currentUserId;
    final statuses = await _meetingStatusRepository.syncStatusesForEvents(
      userId: userId,
      events: events,
    );
    _meetingStatuses.assignAll({
      for (final status in statuses) status.googleEventId: status,
    });
  }

  Future<void> _syncMeetingRecords(List<CalendarEvent> events) async {
    final userId = _currentUserId;
    final records = await _meetingRecordRepository.recentByUser(userId);
    _meetingRecords.assignAll({
      for (final record in records) record.googleEventId: record,
    });
  }

  String get _currentUserId {
    return _authRemoteDataSource.currentUserId;
  }

  Set<String> get _completedRecordEventIds => _meetingStatuses.values
      .where((status) => status.recordStatus == 'completed')
      .map((status) => status.googleEventId)
      .toSet();

  String _mapSyncError(Object error) {
    final text = error.toString();
    if (text.contains('missing_sheets_config')) {
      return 'missing_sheets_config';
    }
    if (text.contains('missing_google_auth')) {
      return 'missing_google_auth';
    }
    return 'sync_failed';
  }

  String _syncErrorMessage(Object error) {
    switch (_mapSyncError(error)) {
      case 'missing_sheets_config':
        return 'GOOGLE_SHEETS_SPREADSHEET_ID 설정이 없습니다.';
      case 'missing_google_auth':
        return 'Google 인증이 필요합니다.';
      default:
        return 'Google Sheets 동기화에 실패했습니다.';
    }
  }

}
