/// 캘린더 탭과 홈 대시보드에서 공용으로 쓰는 일정 상태 컨트롤러다.
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:jg_business/app/routes/app_routes.dart';
import 'package:jg_business/features/auth/presentation/controllers/auth_controller.dart';
import 'package:jg_business/features/calendar/data/datasources/google_calendar_remote_data_source.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/features/calendar/presentation/screens/calendar_event_screen.dart';
import 'package:jg_business/features/meeting/data/models/meeting_record_entity.dart';
import 'package:jg_business/features/meeting/data/models/meeting_status_entity.dart';
import 'package:jg_business/features/meeting/data/repositories/meeting_record_repository.dart';
import 'package:jg_business/features/meeting/data/repositories/meeting_status_repository.dart';
import 'package:jg_business/shared/services/geofence_registration_service.dart';
import 'package:jg_business/shared/services/notification_service.dart';

class CalendarController extends GetxController {
  CalendarController({
    required GoogleCalendarRemoteDataSource remoteDataSource,
    required NotificationService notificationService,
    required AuthController authController,
    required MeetingRecordRepository meetingRecordRepository,
    required MeetingStatusRepository meetingStatusRepository,
    required GeofenceRegistrationService geofenceRegistrationService,
  }) : _remoteDataSource = remoteDataSource,
       _notificationService = notificationService,
       _authController = authController,
       _meetingRecordRepository = meetingRecordRepository,
       _meetingStatusRepository = meetingStatusRepository,
       _geofenceRegistrationService = geofenceRegistrationService;

  final GoogleCalendarRemoteDataSource _remoteDataSource;
  final NotificationService _notificationService;
  final AuthController _authController;
  final MeetingRecordRepository _meetingRecordRepository;
  final MeetingStatusRepository _meetingStatusRepository;
  final GeofenceRegistrationService _geofenceRegistrationService;
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final _isConnected = false.obs;
  bool get isConnected => _isConnected.value;

  final _events = <CalendarEvent>[].obs;
  List<CalendarEvent> get events => _events;
  // eventId 기준으로 상태/기록 문서를 메모리에 들고 있어
  // 홈/캘린더/상세 화면이 빠르게 읽을 수 있게 한다.
  final _meetingStatuses = <String, MeetingStatusEntity>{}.obs;
  final _meetingRecords = <String, MeetingRecordEntity>{}.obs;

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

  final focusedDay = DateTime.now().obs;
  final isMonthCalendarExpanded = false.obs;
  Worker? _authSessionWorker;
  Timer? _geofenceRefreshTimer;

  List<CalendarEvent> get todayEvents {
    /// 오늘 날짜와 겹치는 일정만 추려서 홈/캘린더 상단에 보여준다.
    final today = DateTime.now();
    return _events.where((event) => occursOnDate(event, today)).toList();
  }

  List<CalendarEvent> get upcomingEvents {
    /// 이미 끝난 일정은 제외하고 가까운 미래 일정 위주로 보여준다.
    final now = DateTime.now();
    return _events
        .where((event) {
          final start = event.start?.dateTime ?? event.start?.date;
          final end = event.end?.dateTime ?? event.end?.date;
          if (start == null && end == null) return false;
          return (end ?? start) != null && !(end ?? start)!.isBefore(now);
        })
        .take(6)
        .toList();
  }

  List<CalendarEvent> eventsForDate(DateTime date) {
    /// 주간/월간 캘린더 marker와 날짜 상세 화면이 공용으로 쓴다.
    return _events.where((event) => occursOnDate(event, date)).toList();
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
    final pendingEventIds =
        _meetingStatuses.values
            .where((status) => status.recordStatus == 'pending')
            .map((status) => status.googleEventId)
            .toSet();

    return _events
        .where(
          (event) => event.id != null && pendingEventIds.contains(event.id),
        )
        .take(3)
        .toList();
  }

  int get pendingRecordCount =>
      _meetingStatuses.values
          .where((status) => status.recordStatus == 'pending')
          .length;

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

  bool isOngoing(CalendarEvent event) {
    final now = DateTime.now();
    final start = event.start?.dateTime ?? event.start?.date;
    final end = event.end?.dateTime ?? event.end?.date;

    if (start == null || end == null) return false;
    return !start.isAfter(now) && end.isAfter(now);
  }

  bool occursOnDate(CalendarEvent event, DateTime date) {
    /// 종일 일정과 멀티데이 일정까지 포함해서 특정 날짜와 겹치는지 판단한다.
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
    /// 같은 날짜를 다시 눌렀을 때는 불필요한 rebuild를 막는다.
    final current = focusedDay.value;
    if (current.year == date.year &&
        current.month == date.month &&
        current.day == date.day) {
      return;
    }
    focusedDay.value = date;
  }

  void toggleMonthCalendar() {
    isMonthCalendarExpanded.value = !isMonthCalendarExpanded.value;
  }

  @override
  void onInit() async {
    super.onInit();
    // 앱 시작/로그인 복구 시 먼저 Google Calendar 연결 상태를 초기화한다.
    await _remoteDataSource.initialize();
    _isConnected.value = _remoteDataSource.isConnected;
    _authSessionWorker = ever<int>(_authController.sessionVersionRx, (_) async {
      // 로그인 상태가 바뀌면 캘린더를 다시 읽어 전체 UI를 동기화한다.
      _isConnected.value = _remoteDataSource.isConnected;
      await fetchCalendar(interactive: _isConnected.value);
    });
    _startGeofenceRefreshTimer();
    await fetchCalendar(interactive: false);
  }

  Future<void> fetchCalendar({bool interactive = true}) async {
    try {
      _isLoading.value = true;
      // 1. Google Calendar fetch
      // 2. meeting_status sync
      // 3. meeting_records refresh
      // 4. 알림 재동기화
      final result = await _remoteDataSource.fetchEvents(
        interactive: interactive,
      );
      _isConnected.value = _remoteDataSource.isConnected;

      _events.assignAll(result);
      await _syncMeetingStatuses(result);
      await _syncMeetingRecords(result);
      await _syncGeofences();
      _debugPrintResolvedLocations(result);
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
    Get.toNamed(AppRoutes.calendarEventDetail, arguments: {'event': event});
  }

  void goToEventScreen({required DateTime date, CalendarEvent? event}) {
    Get.toNamed(
      CalendarEventScreen.name,
      arguments: {'event': event, 'date': date},
    );
  }

  void openEventEditor(CalendarEvent event) {
    final date = event.start?.dateTime ?? event.start?.date ?? focusedDay.value;
    Get.toNamed(
      CalendarEventScreen.name,
      arguments: {'event': event, 'date': date},
    );
  }

  @override
  void onClose() {
    _authSessionWorker?.dispose();
    _geofenceRefreshTimer?.cancel();
    super.onClose();
  }

  Future<void> connectCalendar() async {
    if (_isLoading.value) return;

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
        await _syncGeofences();
        _debugPrintResolvedLocations(result);
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

  Future<void> _syncMeetingStatuses(List<CalendarEvent> events) async {
    /// 일정 목록을 기준으로 Firestore 상태 문서를 보정한다.
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
    /// 최근 기록을 eventId 기준 맵으로 들고 있어 상세/홈에서 재사용한다.
    final userId = _currentUserId;
    final records = await _meetingRecordRepository.recentByUser(userId);
    _meetingRecords.assignAll({
      for (final record in records) record.googleEventId: record,
    });
  }

  String get _currentUserId {
    return _authController.currentUserId;
  }

  Future<void> _syncGeofences() async {
    await _geofenceRegistrationService.syncMeetingGeofences(
      _meetingStatuses.values.toList(),
    );
  }

  void _startGeofenceRefreshTimer() {
    // leave geofence 는 "종료 + 5분"이 지난 뒤에야 등록 대상이 되므로
    // 앱이 켜져 있는 동안 주기적으로 다시 계산해 등록 상태를 맞춘다.
    _geofenceRefreshTimer?.cancel();
    _geofenceRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _syncGeofences(),
    );
  }

  void _debugPrintResolvedLocations(List<CalendarEvent> events) {
    // 주소 -> 좌표 변환이 실제로 저장되는지 콘솔에서 바로 확인하기 위한 임시 로그다.
    for (final event in events) {
      final eventId = event.id;
      final locationName = event.location?.trim();
      if (eventId == null || locationName == null || locationName.isEmpty) {
        continue;
      }

      final status = _meetingStatuses[eventId];
      debugPrint(
        'location_resolved'
        ' | title=${event.summary ?? '無題'}'
        ' | location=$locationName'
        ' | lat=${status?.locationLatitude}'
        ' | lng=${status?.locationLongitude}',
      );
    }
  }

  Set<String> get _completedRecordEventIds =>
      _meetingStatuses.values
          .where((status) => status.recordStatus == 'completed')
          .map((status) => status.googleEventId)
          .toSet();
}
